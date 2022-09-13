#!/bin/bash
# Data disks format & mount tool,support xfs/ext4
# Copyright (C) 1998-2020 Tencent Inc. All Rights Reserve
# Permission to copy and modify is granted under the foo license
export PATH=/bin:/sbin:/usr/bin:/usr/sbin

LOGFILE=/tmp/diskformat.log

print_log() {
    log_level=$1
    log_msg=$2
    currentTime=$(date '+%F %T')
    if [[ $log_level = ERROR ]]; then
        echo -e "\033[31m$currentTime [$log_level] $log_msg\033[0m" >&2
    else
        echo "$currentTime [$log_level] $log_msg"
    fi
    echo "$currentTime [$log_level] $log_msg" >>$LOGFILE
}
record_fstab() {
    # e.g.: record_fstab /dev/vdb /data xfs
    local disk=$1
    local mp=$2
    local fstype=$3
    local uuid=$(blkid "$disk" -s UUID -o value 2>/dev/null)
    if [[ -z $uuid ]]; then
        print_log "ERROR" "get uuid of $disk failed"
        return 1
    fi
    [[ -n "$(tail -c1 /etc/fstab )" ]] && echo >>/etc/fstab
    grep -wq "$uuid" /etc/fstab || echo "UUID=$uuid $mp $fstype $MNTOPT 0 0" >>/etc/fstab
}

mkfs_mount() {
    # e.g.: mkfs_mount /dev/vdb /data 10
    local disk="$1"
    local mp="$2"
    local sleeptime="$3"
    [[ -n $sleeptime ]] || sleeptime=1
    local fstype
    if [[ $FSTYPE = auto ]]; then
        mkfscmd="mkfs.xfs -f"
        fstype=xfs
        if ! [ -x /usr/sbin/mkfs.xfs ]; then
            mkfscmd="mkfs.ext4 -F -T largefile4"
            fstype=ext4
        fi
    else
        fstype="$FSTYPE"
        if [[ $fstype = xfs ]]; then
            mkfscmd="mkfs.xfs -f"
        elif [[ $fstype = ext4 ]]; then
            mkfscmd="mkfs.ext4 -F -T largefile4"
        else
            print_log "ERROR" "$disk unkown fstype $fstype"
            echo "$disk err-unkown-fstype" >>"$MNT_RECORD"
            return 1
        fi
    fi
    if ! [ -x /usr/sbin/mkfs.$fstype ]; then
        print_log "ERROR" "$disk bad fstype $fstype, cannot find /usr/sbin/mkfs.$fstype"
        echo "$disk err-no-mkfs.$fstype cmd" >>"$MNT_RECORD"
        return 1
    fi
    if ! [ -b "$disk" ]; then
        print_log "ERROR" "$disk not exists"
        echo "$disk err-disk-not-exists" >>"$MNT_RECORD"
        return 1
    fi
    if grep -q "${mp}[[:space:]]\+" /etc/fstab; then
        local uuid=$(blkid "$disk" -s UUID -o value 2>/dev/null)
        local uuid_fstab=$(grep "${mp}[[:space:]]\+" /etc/fstab | awk '{print $1}' | awk -F'=' '{print $2}')
        local disk_fstab=$(grep "${mp}[[:space:]]\+" /etc/fstab | awk '{print $1}')
        if [[ $uuid = "$uuid_fstab" ]] || [[ $disk = "$disk_fstab" ]]; then
            print_log "INFO" "$disk UUID=$uuid $mp already in fstab"
            echo "$disk info-disk-already-in-fstab" >>"$MNT_RECORD"
            return
        fi
        print_log "ERROR" "$mp exists in fstab but not match $disk"
        echo "$disk err-disk-not-match-in-fstab" >>"$MNT_RECORD"
        return 2
    fi
    if mount | grep -q "^${disk}[[:space:]]\+"; then
        print_log "ERROR" "$disk already used"
        echo "$disk err-disk-already-used" >>"$MNT_RECORD"
        return 3
    fi
    if mount | grep -q "${mp}[[:space:]]\+"; then
        print_log "ERROR" "$disk mount on $mp but mount point already used"
        echo "$disk err-mount-point-$mp-already-used" >>"$MNT_RECORD"
        return 4
    fi
    if ! [[ $(blkid "$disk" -s TYPE -o value) = "$fstype" ]]; then
        if $mkfscmd "$disk"; then
            print_log "INFO" "$disk $fstype formated"
        else
            print_log "err" "$disk $fstype format failed"
            echo "$disk err-format-disk-failed" >>"$MNT_RECORD"
            return 5
        fi
    fi
    sleep $sleeptime
    [ -d "$mp" ] || mkdir "$mp"
    if mount -o $MNTOPT "$disk" "$mp"; then
        print_log "INFO" "$disk mount on $mp success"
        record_fstab "$disk" "$mp" "$fstype"
    else
        print_log "ERROR" "$disk mount on $mp failed"
        echo "$disk err-mount-disk-failed" >>"$MNT_RECORD"
        return 6
    fi
    echo "$disk info-mount-disk-success" >>"$MNT_RECORD"
}

get_datadisks() {
    # find all datadisks
    # input: target -- num / name
    # output: num / name
    # e.g.: get_datadisks num ; get_datadisks name
    local target="$1"
    local disks
    # get all disk device's type, name and mountpoint
    disks=$(lsblk -lpno type,name,mountpoint 2>/dev/null | grep -E '^disk|^part|^lvm|/$')
    # to findout all datadisks, we must exclude all disks/partitions/volumes used by sysdisk
    # sysdisk partition, /dev/vda1
    sysdisk_part=$(echo "$disks"|grep '/$'|awk '{print $2}'|tail -1)
    # sysdisk device path, /dev/vda1
    sysdisk_dev=$(realpath "$sysdisk_part" 2>/dev/null)
    # basename of sysdisk device, vda1
    sysdisk_basename=$(basename "$sysdisk_dev" 2>/dev/null)
    # ../../devices/pci0000:00/0000:00:04.0/virtio1/block/vda/vda1
    sysdisk_class=$(ls -l /sys/class/block/|grep "$sysdisk_basename$"|tail -1|awk '{print $NF}')
    # ../../devices/pci0000:00/0000:00:04.0/virtio1/block/vda
    sysdisk_base=$(dirname "$sysdisk_class" 2>/dev/null)
    # /sys/devices/pci0000:00/0000:00:04.0/virtio1/block/vda/stat
    if [ -f "/sys/class/block/$sysdisk_base/stat" ]; then
        # if stat file exists, sysdisk is a partition of block device vda
        sysdisk=$(basename "$sysdisk_base" 2>/dev/null)
    else
        # otherwise, sysdisk is not a partion
        sysdisk=$(basename "$sysdisk_class" 2>/dev/null)
    fi
    # if sysdisk is lv, findout all physical volumes used by sysdisk logical volume
    # these volumes cannot be used by datadisks
    sysdisk_ident="NULL"
    sysdisk_idents="NULL"
    sysdisk_type=$(echo "$disks"|grep '/$'|tail -1|awk '{print $1}')
    if [[ $sysdisk_type = lvm ]]; then
        vg=$(lvs "$sysdisk_part" 2>/dev/null|tail -1|awk '{print $2}')
        pv_s=$(pvs 2>/dev/null|grep -w "$vg"|awk '{print $1}')
        for pv in $pv_s; do
            pv_dev=$(realpath "$pv" 2>/dev/null)
            pv_basename=$(basename "$pv_dev" 2>/dev/null)
            pv_class=$(ls -l /sys/class/block/|grep "$pv_basename$"|tail -1|awk '{print $NF}')
            pv_base=$(dirname "$pv_class" 2>/dev/null)
            if [ -f "/sys/class/block/$pv_base/stat" ]; then
                sysdisk_ident=$(basename "$pv_base" 2>/dev/null)
            else
                sysdisk_ident=$(basename "$pv_class" 2>/dev/null)
            fi
            sysdisk_idents="$sysdisk_idents|$sysdisk_ident"
        done
    fi
    # so we can exclude all sysdisk related devices now.
    raw_datadisks=$(echo "$disks" | grep 'disk' | grep -Ev "$sysdisk_idents|$sysdisk|$sysdisk_part" | awk '{print $2}')
    pv_lst=$(echo NULL;pvs 2>/dev/null | grep -v PV | awk '{print $1}' | sed 's/[0-9]*$//' | tr '\n' '|' | sed 's/^|//;s/|$//')
    # also exclude devices already been used as lvm physical volumes
    datadisks=$(echo "$raw_datadisks" | grep -Ev "$pv_lst" | sort)
    datadisk_num=$(echo "$datadisks" | grep -v '^$' | wc -l)
    if [[ $target = name ]]; then
        echo "$datadisks"
    else
        echo "$datadisk_num"
    fi
}

is_digit() {
    if [[ "$1" =~ ^([1-9][0-9]{0,14}|0)$ ]]; then
        return 0
    fi
    return 1
}

fix_mp_dirs() {
    # auto fix datadisks mount points dirs
    local num=$1
    local i
    [ -d /data ] || mkdir /data
    [[ $num -eq 0 ]] && return
    for i in $(seq 1 "$num"); do
        [ -d "/data$i" ] || mkdir "/data$i"
    done
}

fix_mp_fstabs() {
    # auto fix datadisks fstab mount points
    local num=$1
    local i
    fix_fstab_mp /data
    [[ $num -eq 0 ]] && return
    for i in $(seq 1 "$num"); do
        fix_fstab_mp "/data$i"
    done
}

fix_fstab_mp() {
    # auto add fstab items when disk mounted but not in fstab
    # e.g.: fix_fstab_mp /data
    local mp=$1
    local fstype
    local disk
    if ! mount | grep -q "${mp}[[:space:]]\+"; then
        return
    fi
    if grep -q "${mp}[[:space:]]\+" /etc/fstab; then
        return
    fi
    disk=$(mount | grep "${mp}[[:space:]]\+" | awk '{print $1}')
    fstype=$(mount | grep "${mp}[[:space:]]\+" | awk '{print $5}')
    if [[ -z $disk ]]; then
        print_log "ERROR" "get diskname for $mp failed, cannot fix fstab"
        return 1
    fi
    if [[ -z $fstype ]]; then
        print_log "ERROR" "err: get fstype for $mp failed, cannot fix fstab"
        return 1
    fi
    record_fstab "$disk" "$mp" "$fstype"
}

is_mounted() {
    local disks=$@
    local count=$#
    local total=0
    local disk
    for disk in ${disks}; do
        if mount | grep -q "^${disk}[[:space:]]\+"; then
            total=$((total+1))
        elif grep -q "^${disk}[[:space:]]\+" "$MNT_RECORD"; then
            total=$((total+1))
        fi
    done
    if [[ $total -eq $count ]]; then
        return 0
    fi
    return 1
}

# begin
if [[ -z $1 ]]; then
    echo "usage: $0 <count|all> [fstype] [mntopt]"
    exit 1
fi

disknum="$1"
FSTYPE="auto"
[[ -n $2 ]] && FSTYPE="$2"
MNTOPT=defaults,noatime,nodiratime
[[ -n $3 ]] && MNTOPT="$3"

print_log "INFO" "format and mount data disks with option: disknum:$disknum fstype:$FSTYPE mntopt:$MNTOPT"
real_disknum=$(get_datadisks num)
datadisks=$(get_datadisks name)
is_digit "$real_disknum" || {
    print_log "ERROR" "get disk num failed"
    exit 1
}

[[ $real_disknum -eq $disknum ]] || {
    if [[ $disknum = "all" ]]; then
        print_log "INFO" "no disknum given, will try to format all $real_disknum datadisks..."
    else
        print_log "ERROR" "disknum not match, found $real_disknum($(echo $datadisks)) but $disknum expected"
        exit 1
    fi
}

if [[ $real_disknum -lt 1 ]]; then
    print_log "ERROR" "no datadisk found."
    exit 1
fi
print_log "INFO" "found $real_disknum datadisks."
echo "found $real_disknum datadisks."
ident=0
[ -d /data ] || mkdir /data
# some fix works before disk format/mount
mount -a >/dev/null 2>&1
fix_fstab_mp /data
if grep -wq /data /etc/fstab; then
    # if /data exists and not first raw-data-disk, ident start from 1
    # or ident still start from 0
    first_disk=$(echo "$datadisks"|head -1)
    data_disk=$(mount |grep -w /data|awk '{print $1}')
    if ! [[ $first_disk = "$data_disk" ]]; then
        ident=1
    fi
fi
# create mount point dirs before mount
if [[ $ident -eq 0 ]]; then
    fix_mp_dirs $((real_disknum-1))
else
    fix_mp_dirs "$real_disknum"
fi
# force mount all disks in fstab before fix fstab
mount -a >/dev/null 2>&1
# fix fstab before mount new disks
fix_mp_fstabs "$real_disknum" >/dev/null 2>&1

MNT_RECORD=$(mktemp)
# disk format and mount
for disk in $datadisks; do
    sleeptime=$ident
    [ $ident -eq 0 ] && ident=""
    mkfs_mount "$disk" "/data${ident}" "$sleeptime" >>$LOGFILE 2>&1 &
    [[ -n $ident ]] || ident=0
    ident=$((ident+1))
done

# waiting for all disks get ready
maxretry=300
retry=0
while true; do
    if is_mounted $datadisks; then
        echo
        if grep -q "err" "$MNT_RECORD"; then
            print_log "ERROR" "$(grep err $MNT_RECORD)"
        else
            print_log "INFO" "$real_disknum disks mounted."
            echo "$real_disknum disks mounted."
        fi
        /bin/rm -f "$MNT_RECORD"
        break
    fi
    echo -n '.'
    sleep 5
    retry=$((retry+1))
    [[ $retry -ge $maxretry ]] || continue
    echo
    print_log "ERROR" "waiting for disks get ready timed out"
    exit 1
done
