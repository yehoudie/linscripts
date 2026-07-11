#!/bin/bash

##
# Detailed `efivar -p -n` dump of every var found by `efivar -l` 
#
##

outFile=./efivars.txt

function printUsage() {
    printf "Usage: %s -o <file> [-v] [-h]\n" $0
    return 0;
}

function printHelp() {
    printUsage
    printf "\n"
    printf "%s File path the values are written to.\n" "-o"
    printf "%s Verbose\n" "-v"
    printf "%s Help\n" "-h"

    return 0;
}

while (("$#")); do
    case "$1" in
        -o | --outfile)
            outFile=$(realpath "$2")
            shift 2
            ;;
        -v | --verbose)
            verbose=1
            shift 1
            ;;
        -* | -h)
            help=1
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


echo "outFile: $outFile"

function dump() {
    local outFile=$1

    if [[ -f $outFile ]]
    then
        efivar -l | xargs -I{} sh -c "echo {}; efivar -p -n {}; printf \"\n\"" > "$outFile"
    else
        efivar -l | xargs -I{} sh -c "echo {}; efivar -p -n {}; printf \"\n\""
    fi
}

dump ${outFile}
