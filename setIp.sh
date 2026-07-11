#!/bin/bash

function setIp()
{
    local dev=$1
    local ip=$2
    local mask=$3
    local gw=$4

    sudo ip address flush dev $dev
    sudo ip route flush dev $dev
    sudo ip address add $ip/$mask brd + dev $dev
    sudo ip route add $gw dev $dev
    sudo ip route add default via $gw dev $dev
    sudo ip address show dev $dev
}

function printUsage() {
    echo "Usage: setIp -d <device> -i <ip> -m <mask> -g <gateway>"
    return 0
}

function printHelp() {
    printUsage
    echo ""
    echo "-d: the network device"
    echo "-i: the ip address to set"
    echo "-m: the network mask as the cidr bit number"
    echo "-g: the default gateway"
    echo "-h: print this"
    return 0
}

while (("$#")); do
    case "$1" in
        -d | --device)
            device=$2
            shift 2
            ;;
        -i | -ip | --ip-address)
            ip=$2
            shift 2
            ;;
        -m | -s | --mask | --subnet-mask)
            mask=$2
            shift 2
            ;;
        -g | -gw | --gateway)
            gw=$2
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

if [[ ${help} == 1 ]]
then
    printHelp
    exit $?
fi

if [[ ${usage} == 1 ]]
then
    printUsage
    exit $?
fi

echo device: $device
echo ip: $ip
echo mask: $mask
echo gateway: $gw

if [[ -z $device || -z ip || -z mask || -z gw ]] 
then
    echo [e] You have to specify a device, ip, mask and gateway.
    printHelp
    exit -1
fi

setIp $device $ip $mask $gw

exit $?
