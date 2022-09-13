#!/bin/bash

#----------------------------------------------------------
# desc: print log
# parameters: log_level, log_msg
# return: workDir
#----------------------------------------------------------
print_log() {
    log_level=$1
    log_msg=$2
    currentTime=$(date '+%F %T')
    echo "$currentTime    [$log_level]    $log_msg"
}


# name of script
baseName=$(basename "$0")
# desc: print how to use
check_input() {
    if [ $# -lt 2 ]; then
        print_log "INFO" "Usage: $baseName <ip> <password> [port]"
        print_log "INFO" "Example:"
        print_log "INFO" "  $baseName 192.168.110.1 123456 22"
        exit 1
    fi
}

install_expect() {
    [[ -x /usr/bin/expect ]] && return 0
    yum install -y expect &>/dev/null
}

ssh_copy_id() {
    local ip=$1
    local password
    local port=$3
    local timeout=$4
    local clientport
    password=$(echo -n "$2" | sed -e 's/\$/\\\$/g')
    ssh-keygen -R "$ip" >/dev/null 2>&1
    ssh-keygen -R "[$ip]:$port" >/dev/null 2>&1
    if [[ -f "$HOME/.ssh/config" ]]; then
        clientport=$(grep Port "$HOME/.ssh/config" | grep -v '^#' | awk '{print $2}')
        ssh-keygen -R "[$ip]:$clientport" >/dev/null 2>&1
    fi
    clientport=$(grep Port /etc/ssh/ssh_config | grep -v '^#' | awk '{print $2}')
    ssh-keygen -R "[$ip]:$clientport" >/dev/null 2>&1
    expect <<EOF
        spawn ssh-copy-id -i $HOME/.ssh/id_rsa.pub -p "$port" "$ip"
        set timeout $timeout
        expect {
            timeout { puts stderr "$ip TimedOut"; exit 1; exp_continue }
            "*yes/no" { send "yes\r"; exp_continue }
            "refused" { puts stderr "$ip ConnectionRefused"; exit 1; exp_continue }
            "*assword" { send "$password\r";
                expect {
                    "denied" { puts stderr "$ip WrongPassword"; exit 1 }
                }
            }
            "reset by peer" { puts stderr "cannot connect to $ip"; exit 1 }
            "No route to host" { puts stderr "cannot connect to $ip"; exit 1 }
            eof
        }
EOF
}

push_key() {
    install_expect
    check_input  "$@"
    print_log "INFO" "copy ssh key to host $1"
    [[ -x /usr/bin/expect ]] || {
        echo "/usr/bin/expect not installed." >&2
        exit 1
    }
    local ip="$1"
    local password="$2"
    local port="$3"
    local timeout="$4"
    [[ -n $port ]] || port=22
    [[ -n $timeout ]] || timeout=30
    [[ -d "$HOME/.ssh" ]] || ( umask 077; mkdir "$HOME/.ssh" )
    [[ -f "$HOME/.ssh/id_rsa" ]] || ssh-keygen -f "$HOME/.ssh/id_rsa" -t rsa -N ''
    if ssh_copy_id "$ip" "$password" "$port" "$timeout" >/dev/null; then
        print_log "INFO" "Ok.copy ssh key to host $1: success"
        return 0
    fi
    print_log "ERROR" "Nok,copy ssh key to host $1: fail"
    return 1
}

########################
#     main program     #
########################
push_key "$@"
