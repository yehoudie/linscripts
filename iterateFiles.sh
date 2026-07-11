
#!/bin/bash

dir=.
b_args=
a_args=
cmd=file
type=*
mode=0
STEPPING_MODE=1
RECURSIVE_MODE=2

function printUsage() {
    printf "Usage: %s -d <dir> [-c <cmd>] [-b <args1>] [-a <args2>] [-t <fileType>] [-r] [-v] [-h]\n" $0
    return 0;
}

function printHelp() {
    printUsage
    printf "\n"
    printf "%s cmd to execute on files. Default 'file'\n" "-c"
    printf "%s args to command before file.\n" "-b"
    printf "%s args to command after file.\n" "-a"
    printf "%s source dir\n" "-d"
    printf "%s recursive dir iteration\n" "-r"
    printf "%s stepping mode\n" "-s"
    printf "%s file type\n" "-t"
    printf "\n"
    printf "Info:\n"
    printf "Command with args will get: <cmd> <args1> {file} <args2>\n"

    return 0;
}

while (("$#")); do
    case "$1" in
        -a | --a_args)
            a_args="$2"
            shift 2
            ;;
        -b | --b_args)
            b_args="$2"
            shift 2
            ;;
        -c | --cmd | --command)
            cmd="$2"
            shift 2
            ;;
        -d | --dir | --directory)
            dir="$2"
            shift 2
            ;;
        -r | --recursive)
            mode=$((mode + RECURSIVE_MODE))
            shift 1
            ;;
        -s | --stepping)
            mode=$((mode + STEPPING_MODE))
            shift 1
            ;;
        -t | --type)
            type="$2"
            shift 2
            ;;
        -v | --verbose)
            verbose=1
            shift 1
            ;;
        -* | -h| --help)
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

if [[ ! -d ${dir} ]]; then
    printf "ERROR: \"%s\" is not a directory!\n" ${source}
    exit $?
fi

echo "dir: $dir"
echo "type: $type"
echo "cmd: $cmd"
echo " b_args: $b_args"
echo " a_args: $a_args"
echo "mode: $mode"

# for file in ${dir}/${type}
# do
    # if [[ ${mode} == STEPPING_MODE ]]; then
        # read -p "Press any key to continue... " -n1 -s
        # echo ""
    # fi
    # printf "file: %s\n" $file
    # echo "-------------------------------"
    # "${cmd}" ${args} "$file"
    # printf "\n\n"
# done


function handleFile() {
    local file=$1
    echo "File: "$file
    
    if [[ $(( mode & STEPPING_MODE )) -eq $(( STEPPING_MODE )) ]]; then
        read -p "Press any key to continue... " -n1 -s
        echo ""
    fi
    # printf "file: %s\n" $file
    echo "-------------------------------"
    "${cmd}" ${b_args} "$file" ${a_args}
    printf "\n\n"
}

function itDir() {
    local dir=$1
    local type=$2
    # type is wrong ??
    echo "type "${type}
    local stepping=$(( mode & STEPPING_MODE ))
    local recursive=$(( mode & RECURSIVE_MODE ))
    local fifo=(${dir})

    while  [ ${#fifo[*]} -gt 0 ]
    do
        local act=${fifo[0]}

        # ${act}/$type does not work
        for file in ${act}/*
        do
            if [[ "${file}" == "./" ]] || [[ "${file}" == "../" ]]
            then
                echo "continue"
                continue
            fi


            if [[ -d "${file}" ]]
            then
                if [[ $recursive == $RECURSIVE_MODE ]]
                then
                    fifo=( "${fifo[@]}" "${file}" )
                fi
            elif [[ -f "${file}" ]]
            then
                handleFile "${file}"
            else
                echo "something else "${file}
            fi

        done

        fifo=( "${fifo[@]:1}" )
    done
}

itDir ${dir} ${type}
