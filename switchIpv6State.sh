#!/bin/bash

# Disable IPv6 in /etc/sysctl.d/40-ipv6.conf

file=/etc/sysctl.d/40-ipv6.conf

MODE_ENABLE=0
MODE_DISABLE=1
MODE_CHECK=-1

mode=$MODE_DISABLE
device=all

function switchIpv6()
{
    local device=$1
    local mode=$2
    
    echo "writing to ${file}"
    
    >${file} echo "net.ipv6.conf.$device.disable_ipv6 = $mode"

    # add address privacy
    if [[ $mode == $MODE_ENABLE ]]
    then
        >>${file} echo "net.ipv6.conf.$device.use_tempaddr = 2"
        >>${file} echo "net.ipv6.conf.default.use_tempaddr = 2"
    fi

	echo -e
    cat ${file}

    systemctl restart systemd-sysctl.service
}

function printUsage() {
    echo "Usage: switchIpv6State [-e|-d|-c] [-t <device>]"
    return 0
}

function printHelp() {
    printUsage
    echo ""
    echo "-e: enable ipv6"
    echo "-d disable ipv (default)"
    echo "-c: check current state"
    echo "-t: name of target device. default: all"
    return 0
}

while (("$#")); do
    case "$1" in
        -d | --disable)
            mode=$MODE_DISABLE
            shift 1
            ;;
        -e | --enable)
            mode=$MODE_ENABLE
            shift 1
            ;;
        -c | --check)
            mode=$MODE_CHECK
            shift 1
            ;;
        -t | --device)
            device=$2
            shift 2
            ;;
        -h | --help)
            help=1
            break
            ;;
        -* | --usage)
            usage=1
            break
            ;;
        *) # No more options
            break
            ;;
    esac
done

if [[ ${help} == 1 ]]; then
    printHelp
    exit $?
fi

if [[ ${usage} == 1 ]]; then
    printUsage
    exit $?
fi


if [[ ${mode} -ge 0 ]]
then
    switchIpv6 $device ${mode}
else
    cat ${file}
fi

exit $?
