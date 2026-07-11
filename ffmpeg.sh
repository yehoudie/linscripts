#!/bin/bash

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"

CMD_NONE=0
CMD_USAGE=1
CMD_HELP=2
CMD_CUT=3
CMD_BATCH=4
CMD_TEMPLATE=5

CUT_FLAG_TITLE_NR=1

batch_file=
cmd=$CMD_NONE
verbose=0

template_path="/tmp/titles.txt"

infile=
outfile=
start=
end=


#
# Per-file options (input and output):
# -f <fmt>            force container format (auto-detected otherwise)
# -t <duration>       stop transcoding after specified duration
# -to <time_stop>     stop transcoding after specified time is reached
# -ss <time_off>      start transcoding at specified time
# -vcodec <codec>     alias for -c:v (select encoder/decoder for video streams)
# -acodec <codec>     alias for -c:a (select encoder/decoder for audio streams)
#
# params:
# #1 start
# #2 to
# #3 in file
# #4 out file
#
function cutVideo() {
    local start="$1"
    local to="$2"
    local if="$3"
    local of="$4"
    
    ffmpeg -ss $start -to $to -i "$if" -vcodec copy -acodec copy "$of"

    
    return $?
}

#
# read from batch file
#
# 1: infile
# 2: outdir
# 3: flags: 1=add title number  
# 4...: start end basename
#
# e.g.
# Music/long.mp4
# Music/out
# 1
# 00:00:00 00:03:18 Song1
# 00:03:18 00:05:55 Song2
#
function iterateFile() {
    local batch_file="$1"

    local nrLines=$(wc -l < "$batch_file")
    local lineCount=1

    echo "batch_file: "$batch_file
    
    if [ ! -f "$batch_file" ]
    then
        echo "[e] file "$batch_file" does not exist"
        return $?
    fi
    
    # if [[ "$file" == *"music.txt" ]]; then
        # outformat="-o $music_o"
    # elif [[ "$file" == *"dianying.txt" ]]; then
        # outformat="-o $dianying_o"
        # st="$sub"
    # fi
    
    local infile=$(sed -n '1p' "$batch_file")
    # local infile=$(read -r line < "$batch_file")
    echo "infile: "$infile
    local outdir=$(sed -n '2p' "$batch_file")
    local flags=$(sed -n '3p' "$batch_file")
    echo "outdir: "$outdir
    local startline=4
    local nrCuts=$((nrLines-startline-1))
    local start=
    local end=
    local name=
    local of=
    local title_nr=1
    
    local baseName="${infile##*/}"
    local base=${baseName%.*}
    local baseCb=${#base}
    local type=${baseName#*.}
    echo baseName=$baseName
    echo type=$type
    
    while IFS="" read -r line || [ -n "$line" ]
    do
        if (( ${#line} > 1 )); then
            echo $lineCount " / " $nrCuts
            # echo $line
            local parts=($line)
            local nrParts=${#parts[@]}
            
            if (( $nrParts < 3 )); then 
                echo [i] Skipping invalid line: $line
                lineCount=$((lineCount+1))
                continue
            fi
            
            if (( $((flags & $CUT_FLAG_TITLE_NR)) == $CUT_FLAG_TITLE_NR )); then
                ep=1
            fi
        
            # echo nrParts=$nrParts
            start=${parts[0]}
            end=${parts[1]}
            nr_name_parts=$((nrParts-2))
            # echo "nr_name_parts: "$nr_name_parts
            name=${parts[@]:2:$nr_name_parts}
            if (( $((flags & $CUT_FLAG_TITLE_NR)) == $CUT_FLAG_TITLE_NR )); then
                printf -v tnr "%02d" $title_nr
                name="$tnr - $name"
            fi
            of="$outdir/$name.$type"
            echo start=$start
            echo end=$end
            echo name=$name
            echo of=$of
            echo title_nr=$title_nr
            cutVideo $start $end "$infile" "$of"
            echo "finished with code "$?
            lineCount=$((lineCount+1))
            title_nr=$((title_nr+1))
        fi
    done < <(tail -n "+$startline" "$batch_file")
    
    return $?
}

function createTemplate() {
    echo "createing template in "$template_path
    
    echo "Music/long.mp4" > "$template_path"
    echo "Music/out" >> "$template_path"
    echo "1" >> "$template_path"
    echo "00:00:00 00:03:18 Song1" >> "$template_path"
    echo "00:03:18 00:05:55 Song2" >> "$template_path"

    return 0;
}

function printUsage() {
    echo "Usage: $0 [-i <infile> -o <outfile> -s <start> -e <end>] [-b <file>]"
    return 0;
}

function printHelp() {
    printUsage
    echo ""
    echo "-i input file"
    echo "-o output file"
    echo "-s start time (hh:mm:ss)"
    echo "-e end time (hh:mm:ss)"
    echo "-b batch file"
    echo "-h Print this."
    return 0;
}

while (("$#")); do
    case "$1" in
        -b | --batch-file)
            batch_file=$2
            cmd=$CMD_BATCH
            shift 2
            ;;
        -e | --end)
            end=$2
            shift 2
            ;;
        -h | --help)
            cmd=$CMD_HELP
            break
            ;;
        -i | -if | --in-file)
            infile=$2
            shift 2
            ;;
        -o | -of | --out-file)
            outfile=$2
            shift 2
            ;;
        -t | --template)
            cmd=$CMD_TEMPLATE
            shift 1
            ;;
        -s | -ss |--start)
            start=$2
            shift 2
            ;;
        -v | --verbose)
            verbose=1
            shift 1
            ;;
        -* | --usage)
            cmd=$CMD_USAGE
            break
            ;;
        *) 
            cmd=$CMD_USAGE
            break
            ;;
    esac
done

if (( $verbose == 1 )); 
then
    echo "infile" $infile
    echo "outfile" $outfile
    echo "start" $start
    echo "end" $end
    echo "cmd" $cmd
    echo -e
fi



if [[ -n "$start" && -n "$end" && -n "$infile" && -n "$outfile"  ]];
then
    cmd=$CMD_CUT
fi

if ((  $cmd == $CMD_NONE ));
then
    cmd=$CMD_USAGE
fi



if (( $cmd == $CMD_BATCH ));
then
    iterateFile "$batch_file"
elif (( $cmd == $CMD_TEMPLATE ));
then
    createTemplate
elif (( $cmd == $CMD_CUT ));
then
    cutVideo "$start" "$end" "$infile" "$outfile"
elif (( $cmd == $CMD_USAGE ));
then
    printUsage
elif (( $cmd == $CMD_HELP ));
then
    printHelp
fi


# echo "[i] no mode set!"
# printUsage

exit $?
