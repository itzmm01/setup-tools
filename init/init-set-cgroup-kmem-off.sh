#!/bin/bash

#----------------------------------------------------------
# desc: print log
# parameters: log_level, log_msg
# return: workDir
#----------------------------------------------------------
function print_log()
{
    log_level=$1
    log_msg=$2
    currentTime=`echo $(date +%F%n%T)`
    echo "$currentTime    [$log_level]    $log_msg"
}

# name of script
baseName=$(basename $0)

# input: none
# output: 1/0
function set_cgroup_kmem_off()
{
  print_log "INFO" "set cgroup kmem off"
  if ! grep -q "cgroup.memory=nokmem" /proc/cmdline; then
    if ! grep -q "cgroup.memory=nokmem" /etc/default/grub; then
      sed -i -e 's|^GRUB_CMDLINE_LINUX=\"|GRUB_CMDLINE_LINUX=\"cgroup.memory=nokmem |g' /etc/default/grub
    fi

    if [[ -d /sys/firmware/efi ]]; then
      # for UEFI
      grub2-mkconfig  -o /boot/efi/EFI/centos/grub.cfg
    else
      # for BIOS
      grub2-mkconfig  -o /boot/grub2/grub.cfg
    fi

    if [[ $? ]]; then
      print_log "INFO" "Ok cgroup kmem: off"
      return 0
    fi
    print_log "ERROR" "Nok set cgroup kmem off:failed"
    return 1
  else
      print_log "INFO" "Ok cgroup kmem: off"
      return 0
  fi
}

########################
#     main program     #
########################
set_cgroup_kmem_off