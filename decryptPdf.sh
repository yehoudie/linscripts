#!/bin/bash

source=""
target=""
n=0
s=0
lnopt=0
FLAG_VERBOSE=1
FLAG_RECURSIVE=2
flags=0

function printUsage() {
    printf "Usage: %s -s source/dir -t target/dir [-v] [-h]\n" $0
    return 0;
}

function printHelp() {
    printUsage
    printf "\n"
    printf "%s source dir with encrypted pdfs\n" "-s"
    printf "%s target dir to save the decrpyted pdfs in\n" "-t"
    printf "%s recursive iteration of directories\n" "-r"
    printf "%s verbose mode\n" "-v"
    printf "%s print this\n" "-h"

    return 0;
}

while (("$#")); do
    case "$1" in
        -r | --recursive)
            flags=$((flags | FLAG_RECURSIVE))
            shift 1
            ;;
        -s | --source)
            source=$(realpath "$2")
            shift 2
            ;;
        -t | --target)
            target=$(realpath "$2")
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

if [[ ! -d ${source} ]]; then
    printf "[!] \"%s\" is not a directory!\n" ${source}
    printUsage
    exit $?
fi

if [[ ! -d ${target} ]]; then
    printf "[!] \"%s\" is not a directory!\n" ${target}
    printUsage
    exit $?
fi


if [[ $((flags & FLAG_VERBOSE)) -gt 0 ]]
then
    echo "source dir: ${source}"
    echo "target dir: ${target}"
fi



function decrypt() {
    local filePath=$1
    local targetDir=$2
    local fileCb=${#filePath}
    
    local baseName=${filePath##*/}
    local base=${baseName%.*}
    local baseCb=${#base}
    local type=${baseName#*.}

    if [[ $((flags & FLAG_VERBOSE)) == 1 ]]; then
        echo "decrypt()"
        echo "  filePath = $filePath"
        #~ echo "  fileCb = $fileCb"
        #~ echo "  baseName = $baseName"
        #~ echo "  baseCb = $baseCb"
        echo "  base: $base"
        echo "  type = $type"
    fi
    
    if [[ $baseCb -gt 4 ]] && [[ ${base:$(($baseCb-4)):$(($baseCb-1))} == "-dec" ]]
    then
        echo [!] dec file
        return
    fi
    
    if [[ $type != "pdf" ]]
    then
        echo [!] Not a pdf file!
        return
    fi
    
    local isEnc=$( qpdf --show-encryption "$filePath" )
    if [[ $( qpdf --show-encryption "$filePath" ) == "-File is not encrypted" ]]
    then
        return
    fi
    
    local targetName=$targetDir"/"$base"-dec.pdf"
    if [[ $((flags & FLAG_VERBOSE)) -gt 0 ]]; then
        echo "  targetName = $targetName"
    fi

    qpdf --decrypt "$filePath" "$targetName"
}

function itDir() {
    local dir=$1
    local target=$2
    local fifo=(${dir})

    while  [ ${#fifo[*]} -gt 0 ]
    do
        local act=${fifo[0]}

        for file in ${act}/*
        do
            # skip . and .. 
            if [[ ${file} == "./" ]] || [[ ${file} == "../" ]]
            then
                continue
            fi

            # add dir to fifo
            if [[ -d ${file} ]] && [[ $((flags & FLAG_RECURSIVE)) -gt 0 ]]
            then
                fifo=( "${fifo[@]}" ${file} )
            elif [[ -f ${file} ]]
            # decrypt files
            then
                decrypt "${file}" "${target}"
            fi
        done

        fifo=( "${fifo[@]:1}" )
    done


#    for file in ${dir}/*
#    do
#        if [[ ${file} == "./" ]] || [[ ${file} == "../" ]]
#        then
#            continue
#        fi
#
#        i=$((i+1))
##        echo "${i}"
##        echo " - file: ${file}"
##        echo " - c: ${c}"
#
#        if (( i <= s ))
#        then
#            continue
#        fi
#        # if [[ ${i} -gt ${n} ]]; then break; fi; # posix
#
#
#        if [[ -d ${file} ]]
#        then
#            itDir ${file}
#        elif [[ -f ${file} ]]
#        then
#            makeLink ${file}
#        fi
#
#        if (( c >= n ))
#        then
#            break
#        fi
#
#    done
}

itDir ${source} ${target}
