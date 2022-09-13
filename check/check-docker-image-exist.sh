#!/bin/bash

# print log functions
function print_log() {
    log_level=$1
    log_msg=$2
    currentTime=$(echo $(date +%F%n%T))
    echo "$currentTime    [$log_level]    $log_msg"
}

# name of script
baseName=$(basename "$0")

if [ $# -lt 1 ]; then
    #输入的参数少于1个
    print_log "ERROR" "Missing argument"
    print_log "INFO" "Usage: $baseName <images-tag>"
    print_log "INFO" "Example:"
    print_log "INFO" "$baseName mysql:latest"
    exit 1
fi

# desc: check docker images exist
# input: docker images tag
# output: 1/0
function check_images() {
    tag=$1
    name=$(echo $tag | awk -F: '{print $1}')
    version=$(echo $tag | awk -F: '{print $2}')

    print_log "INFO" "Check docker images $1"

    if docker images | grep -Eoq "^${name} "; then
        if [[ ${version} == $(docker images | grep -E "^${name} " | awk '{print $2}') ]]; then
            print_log "INFO" "Image $1 already exists."
            print_log "INFO" "Ok"
            return 0
        else
            print_log "ERROR" "Tag version don't match!"
            exit 1
        fi
    else
        print_log "ERROR" "Images doesn't exists!"
        exit 1
    fi

}

check_images "$1"
