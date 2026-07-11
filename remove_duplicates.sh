#!/bin/bash
declare -A arr
shopt -s globstar

script_name=$0
script_name=${script_name##*/}

target_dir=
mask=*

FLAG_VERBOSE=1
FLAG_RECURSIVE=2
FLAG_DRY=4
flags=0

function printUsage() {
    printf "Usage: %s -t <target_dir> [-m <mask>] [-r] [-d] [-v] [-h]\n" $script_name
    return 0;
}

function printHelp() {
    printUsage
    printf "\n"
    printf "%s target dir\n" "-t"
    printf "%s file filter mask\n" "-m"
    printf "%s recursive iteration of directories. overwrites mask\n" "-r"
    printf "%s dry run. just showing to be removed files.\n" "-d"
    printf "%s verbose mode\n" "-v"
    printf "%s print this\n" "-h"

    return 0;
}

while (("$#")); do
    case "$1" in
        -d | --dry)
            flags=$((flags | FLAG_DRY))
            shift 1
            ;;
        -m | --mask)
            mask="$2"
            shift 2
            ;;
        -r | --recursive)
            flags=$((flags | FLAG_RECURSIVE))
            shift 1
            ;;
        -t | --target-dir)
            target_dir=$(realpath "$2")
            shift 2
            ;;
        -v | --verbose)
            flags=$((flags | FLAG_VERBOSE))
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

if [[ $((flags & FLAG_RECURSIVE)) -gt 0 ]]
then
    mask=**
fi

if [[ $((flags & FLAG_VERBOSE)) -gt 0 ]]
then
    echo "target_dir: $starget_dir"
    echo "mask: $mask"
    echo "flags: $flags"
    echo "  verbose"
    if [[ $((flags & FLAG_RECURSIVE)) -gt 0 ]]; then
        echo "  recursive"
    fi
    if [[ $((flags & FLAG_DRY)) -gt 0 ]]; then
        echo "  dry run"
    fi

fi

if [[ -z "$target_dir" ]]
then
    printf "[!] -d not set!\n"
    printUsage
    exit
fi

if [[ ! -d "${target_dir}" ]]; then
    printf "[!] \"%s\" is not a directory!\n" ${target_dir}
    printUsage
    exit $?
fi

for file in "${target_dir}"/$mask; do
    [[ -f "$file" ]] || continue
    # echo "$file"
   

    read cksm _ < <(md5sum "$file")
    
    if ((arr[$cksm]++)); then 

        if [[ $((flags & FLAG_DRY)) -gt 0 ]]
        then
            echo "rm $file"
            echo "  md5: $cksm"
        else
            rm "$file"
        fi
        
    fi
done

