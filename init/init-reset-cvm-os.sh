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

usage() {
    echo "Usage:$(basename "$0") <reset> <ip>"
    echo "      reset ip           - reset specific node"
    echo "      reset self         - reset current node"
    exit
}
if [ $# -lt 1 ]; then
    usage
fi

red() {
    echo -e "\033[31m$*\033[0m" >&2
}

green() {
    echo -e "\033[32m$*\033[0m"
}

err_exit() {
    red "$*"
    exit 1
}

urlencode(){
    local encoded_str=`echo "$*" | awk 'BEGIN {
        split ("1 2 3 4 5 6 7 8 9 A B C D E F", hextab, " ")
        hextab [0] = 0
        for (i=1; i<=255; ++i) {
            ord [ sprintf ("%c", i) "" ] = i + 0
        }
    }
    {
        encoded = ""
        for (i=1; i<=length($0); ++i) {
            c = substr ($0, i, 1)
            if ( c ~ /[a-zA-Z0-9.-]/ ) {
                encoded = encoded c             # safe character
            } else if ( c == " " ) {
                encoded = encoded "+"   # special handling
            } else {
                # unsafe character, encode it as a two-digit hex-number
                lo = ord [c] % 16
                hi = int (ord [c] / 16);
                encoded = encoded "%" hextab [hi] hextab [lo]
            }
        }
        print encoded
    }' 2>/dev/null`
    echo $encoded_str
}

array(){
    local array_name=$1
    local array='echo ${'$array_name'[@]}'
    eval $array
}

_strkey(){
    local str=$1
    local key=$2
    local strkey=`echo -n "$str" | openssl sha1 -hmac "$key" -binary | base64`
    echo $strkey
}

para_sort(){
    local para_array=($@)
    local i=0
    local tmp_file="/tmp/.${USER}_tmp_para.txt"

    rm -rf $tmp_file

    if [ $# -gt 0 ];then
        while [ $i -le ${#para_array[@]} ]
        do
            local paraid=${para_array[$i]}
            let i=$i+1
            local paravs=${para_array[$i]}
            let i=$i+1
            echo "$paraid $paravs" >>$tmp_file
        done
    fi

    local sort_para=(`cat $tmp_file | gawk '{aa[$1]=$2}END{len=asorti(aa,bb);for(i=1;i<=len;i++){print bb[i]"\t"aa[bb[i]]}}'`)
    rm -rf $tmp_file
    echo "${sort_para[@]}"
}

para_join(){
    local sort_para=($@)
    local i=0
    local parastr=""

    while [ $i -lt $# ];do
        parastr=$parastr"${sort_para[$i]}="
        let i=$i+1
        parastr=${parastr}"${sort_para[$i]}&"
        let i=$i+1
    done
    echo ${parastr%&}
}

signstr(){
    local url=$1
    local para_str=(`array $2`)
    local key=$3
    local i=0

    while [ $i -lt ${#para_str[@]} ]
    do
        para_str[$i]=$(echo ${para_str[$i]} | sed 's/_/./')
        let i=$i+2
    done

    para_str=($(para_sort "${para_str[@]}"))

    local para_join=$(para_join "${para_str[@]}")

    local srcstr="GET$url?$para_join";

    _strkey $srcstr $key
}

_check_variable(){
    if [ -z "$SID" ] || [ -z "$SKEY" ]; then
        red "need to set SID and SKEY in env"
        exit
    fi
}

qcloud_api(){
    _check_variable
    [ $# -lt 1 ] && {
        red "parameter error"
        exit
    }

    if ! [[ -n $ZONE ]]; then
        ZONE=$(curl -s http://metadata.tencentyun.com/meta-data/placement/region|awk -F'-' '{print $NF}')
    fi
    [[ $ZONE = null ]] && {
        red "cannot get zone name"
        exit 1
    }
    local url="cvm.api.qcloud.com/v2/index.php"
    local id=$SID
    local key=$SKEY
    local zone=$ZONE
    local OUTFILE=/tmp/.${USER}_json.out
    local action=$1 ; shift
    local private_para=($(echo "$@"))

    let local private_count=${#private_para[@]}%2

    [ $private_count -eq 1 ] && {
        red "parameter error"
        exit 1
    }

    local para_array=('Nonce' $RANDOM 'Timestamp' `date +%s` 'Region' "$zone")
    para_array=(${para_array[@]} "Action" "$action" "SecretId" "$id" ${private_para[@]})

    local sigstr=`signstr $url "para_array" $key`
    para_array=(${para_array[@]} "Signature" $sigstr)

    local i=1
    while [ $i -lt ${#para_array[@]} ]
    do
        para_array[$i]=`urlencode ${para_array[$i]}`
        let i=$i+2
    done

    para_array=($(para_sort "${para_array[@]}"))
    local parastr=$(para_join "${para_array[@]}")

    local req="https://$url?$parastr"
    [[ "$DEBUG" = 1 ]] && echo $req

    curl -s $req -o $OUTFILE

    if [ $? -ne 0 ];then
        red "Curl command exec failed!"
        return 1;
    fi
}

_res_check(){
    local file=/tmp/.${USER}_json.out

    local res=`awk -F ',' '{for(i=1;i<=NF;i++){if($i~/"code":.*/){split($i,code,":");print code[2];break}}}' $file`
    if [ "$res" == "0" ];then
        green "successful."
        return 0
    else
        if ! [[ -n "$res" ]] &&  ! grep -q Error $file; then
            green "successful."
            return 0
        fi
        red "failed. ( $(cat $file) )"
        return 1
    fi
}

parse_host(){
    local file=/tmp/.${USER}_json.out

    local all_json=$(awk -F ',' '{for(i=1;i<=NF;i++){if($i~/instanceName/){printf $i"->"};if($i~/Ip/){printf $i"->"};if($i~/instanceId/){printf $i"\n"}}}' $file)
    local all_jsons=()

    for i in "${all_json[@]}"; do
        all_jsons=(${all_jsons[@]} $i)
    done

    all_jsons[0]=$(echo ${all_jsons[0]} | sed 's/instanceSet"://')
    local hostinfo=""
    local instance_name=""
    local lan_ip=""
    local wan_ip=""
    local instance_id=""
    local i=0

    for ((i=0;i<${#all_jsons[@]};i++))
    do
        hostinfo=$(echo ${all_jsons[$i]} | sed -r 's/"|\{|\}|\[|\]//g')
        instance_name=$(echo $hostinfo | awk -F '->' '{print $1}' | awk -F ':' '{print $2}')
        lan_ip=$(echo $hostinfo | awk -F '->' '{print $2}' | awk -F ':' '{print $2}')
        wan_ip=$(echo $hostinfo | awk -F '->' '{print $3}' | awk -F ':' '{print $2}')
        instance_id=$(echo $hostinfo | awk -F '->' '{print $4}' | awk -F ':' '{print $2}')
        echo "$instance_name $lan_ip $wan_ip $instance_id"
    done
}


#instancesd start/stop/restart instance
instancesd(){
    [ $# -eq 0 ] && {
        red "parameter error"
        exit
    }
    local flag=$1 ; shift
    local instanceids=($(echo $@))
    local instanceid=""
    local para_list=()
    local num=1

    for instanceid in "${instanceids[@]}"; do
        para_list=(${para_list[@]} "instanceIds.${num}" $instanceid)
        let num=$num+1
    done

    case $flag in
        "start")   flag="StartInstances" ;;
        "stop")    flag="StopInstances"  ;;
        "restart") flag="RestartInstances" ;;
        *)         echo "Invalid option" && exit ;;
    esac

    qcloud_api $flag "${para_list[@]}"
    _res_check
}

#Ex: instance_reset $instanceid $password [$img]
instance_reset(){
    [ $# -lt 2 ] && {
        red "parameter error"
        exit
    }
    local instanceid=$1
    local password=$2
    local img=${3}
    [[ "$DEBUG" = 1 ]] && echo "ins:$instanceid pass:$password img:$img"
    if [[ -n $img ]]; then
        qcloud_api "ResetInstance" "Version" "2017-03-12" "InstanceId" $instanceid "ImageId" $img "LoginSettings.Password" $password
    else
        qcloud_api "ResetInstance" "Version" "2017-03-12" "InstanceId" $instanceid "LoginSettings.Password" $password
    fi
    _res_check
}

reboot_instance(){
    [ $# -lt 1 ] && {
        red "parameter error"
        exit
    }
    local instanceid
    instanceid=$(get_id $1)
    [[ -n $instanceid ]] || {
        red "cannot get instanceid for $1"
        return 1
    }
    qcloud_api "RebootInstances" "Version" "2017-03-12" "InstanceIds.0" $instanceid "ForceReboot" "TRUE"
    _res_check
}

desc_instance(){
    [ $# -lt 1 ] && {
        red "parameter error"
        exit
    }
    local instanceid=$1
    qcloud_api "DescribeInstances" "Version" "2017-03-12" "InstanceIds.0" $instanceid
    _res_check
}

is_ip() {
    local ip=$1
    local stat=1

    if [[ $ip =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
        OIFS=$IFS
        IFS='.'
        ip=($ip)
        IFS=$OIFS
        [[ ${ip[0]} -le 255 && ${ip[1]} -le 255 \
            && ${ip[2]} -le 255 && ${ip[3]} -le 255 ]]
        stat=$?
    fi
    return $stat
}

is_qcloud() {
    if curl -s --connect-timeout 7 http://metadata.tencentyun.com >/dev/null 2>&1; then
        return 0
    fi
    return 1
}

get_id() {
    local target=$1
    local id
    local ip
    if [[ $target = self ]]; then
        local selfid=$(curl -s http://metadata.tencentyun.com/meta-data/instance-id)
        if ! [[ -n $selfid ]]; then
            red "cannot get id for self"
            exit 1
        fi
        if ! echo $selfid | grep -q '^ins-'; then
            red "cannot get instanceid for $ip"
            exit 1
        fi
        echo $selfid
    else
        local instanceid=""
        ip=$target
        instanceid=$(ssh -o StrictHostKeyChecking=no $ip 'curl -s http://metadata.tencentyun.com/latest/meta-data/instance-id 2>/dev/null' 2>/dev/null </dev/null)
        if ! [[ -n $instanceid ]]; then
            red "cannot get id for $ip"
            exit 1
        fi
        if ! echo $instanceid | grep -q '^ins-'; then
            red "cannot get instanceid for $ip"
            exit 1
        fi
        echo "$instanceid"
    fi
}

check_api() {
    local selfid
    selfid=$(curl -s http://metadata.tencentyun.com/meta-data/instance-id)
    if ! [[ -n $selfid ]]; then
        red "cannot get id for this node"
        exit 1
    fi
    desc_instance $selfid
    cat /tmp/.${USER}_json.out
}

reinstall_os() {
    local id
    local target="$1"
    if ! [[ -n $target ]]; then
        usage
        exit 1
    fi
    declare -A arr
    arr[centos65]=img-7fwdvfur
    arr[centos66]=img-h5le2uy5
    arr[centos67]=img-9iwld2rx
    arr[centos68]=img-6ns5om13
    arr[centos69]=img-5o093vwk
    arr[centos70]=img-b1ve77s9
    arr[centos71]=img-9q2lxkar
    arr[centos72]=img-31tjrtph
    arr[centos73]=img-dkwyg6sr
    arr[centos74]=img-8toqc6s3
    arr[centos75]=img-oikl1tzv
    arr[centos76]=img-9qabwvbn
    arr[centos77]=img-1u6l2i9l
    arr[centos78]=img-3la7wgnt
    arr[centos80]=img-25szkc8t
    arr[centos82]=img-n7nyt2d7
    arr[tlinux24]=img-hdt9xxkt

    if ! is_qcloud; then
        echo "only qcloud supported."
        exit 1
    fi

    if [[ -n $IMGID ]]; then
        imgid=$IMGID
    else
        imgid=""
        [[ -n $OS ]] && imgid=${arr[$OS]}
    fi
    if ! [[ -n $ROOTPWD ]]; then
        red "cannot get ROOTPWD from env"
        exit 1
    fi
    for id in $(get_id $target); do
        echo -ne "reset $target $id ... "
        instance_reset $id $ROOTPWD $imgid
        local ret=$?
        while [ $ret -ne 0 ]; do
            echo -ne "\033[31mretry $id \033[0m... "
            sleep 10
            instance_reset $id $ROOTPWD $imgid
            ret=$?
        done
    done
}

case $1 in
    reset)
        shift
        reinstall_os "$@"
        ;;
    *)
        usage
        ;;
esac
