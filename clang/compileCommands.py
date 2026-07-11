#!python3

import argparse
from pathlib import Path
import sys
import os

PROGRAM_DESCRIPTION = 'Creates clang compile_commands.json required for vscodium.'
PROGRAM_NAME = 'compileCommands.json'
PROGRAM_VERSION = '1.0.0'


#
# "directory": "$directory",
# "command": "gcc -o build/FShare -Wl,-z,relro,-z,now -D_FILE_OFFSET_BITS=64 -L/usr/lib -lcrypto {f:$file_path}} -Ishared",
# "file": "$file_path"
#
def addEntry(file_path:FilePath, directory:str, command:str, of:BufferedRandom):
        
    command = command.replace("{f}", file_path)
    
    e = '    {0}{1}'.format("{", os.linesep)
    e += '        "directory": "{0}"{1}'.format(directory, os.linesep)
    e += '        "command": "{0}"{1}'.format(command, os.linesep)
    e += '        "file": "{0}"{1}'.format(file_path, os.linesep)
    e += '    {0},{1}'.format("}", os.linesep)

    # print("%s" % e)
    of.write(e.encode("utf-8"))
            
    return 0


def check_arguments():
    parser = argparse.ArgumentParser()
    parser.description = PROGRAM_DESCRIPTION
    parser.usage = 'python %(prog)s [options] file1 [file2 ...]'
    parser.add_argument('-v', '--version', action='version', version='{} {}'.format(PROGRAM_NAME, PROGRAM_VERSION))
    parser.add_argument('-c', '--command', help='The "command" element of each entry. Place an "f" where the file should apear. E.g. "gcc {f}"', type=str, required=True)
    parser.add_argument('-d', '--directory', help='The "directory" element of each entry.', type=str, required=True)
    parser.add_argument('-o', '--out_file', help='The output file.', type=str, required=True, default="compile_commands.json")
    parser.add_argument('-r', '--recursive', help='Iterate the files of a directory recursively.', action='store_true', required=False)
    parser.add_argument('-f', '--filetype', help='Filetype filter for a directory.', default="*.c", type=str, required=False)
    parser.add_argument('files', nargs='+', help='A list of files or direcotry pathes to create entries in the json.', default=None, type=str)

    return parser.parse_args()


if __name__ == '__main__':
    args = check_arguments()
    if args is None:
        sys.exit()

    files = args.files
    number_of_files = len(files)
    print("number_of_files: %u" % number_of_files);
    recursive = args.recursive
    print("recursive: %s" % str(recursive));
    file_type_mask = args.filetype
    # file_type_mask = "*"
    print("file_type_mask: %s" % file_type_mask);
    out_file = args.out_file
    print("out_file: %s" % out_file);
    directory = args.directory
    print("directory: %s" % directory);
    command = args.command
    print("command: %s" % command);
    
    if not "{f}" in command:
        print("[e] You have to put a \"{f}\" into your command to set where the should apear in the string!")
        sys.exit()


    of = open(out_file, 'wb+')
    # of = open(out_file, 'wb+', encoding="utf-8")
    print("of:·{}".format(of))

    e = '[{0}'.format(os.linesep)
    of.write(e.encode("utf-8"))
    # print("%s" % e)
    
    for f in files:
        file_path = Path(f).expanduser()
        print("file_path: %s" % file_path)
        if file_path.is_file():
            print("file: %s" % file_path)
            s = addEntry(path, directory, command, of)
        elif file_path.is_dir():
            print("dir: %s" % file_path)
            if recursive:
                gfilter = '**/%s' % file_type_mask
            else:
                gfilter = './%s' % file_type_mask
            
            for path in file_path.glob(gfilter):
                print("  file: %s" % path)
                s = addEntry(path.as_posix(), directory, command, of)
        else:
            print("[e] Did not find %s" % f)
    
    # remove last "," (and "\n")
    of.seek(-2, os.SEEK_END)
    of.truncate()

    # readd removed "\n" and close bracket
    e = '{0}]{1}'.format(os.linesep, os.linesep)
    # print("%s" % e)
    of.write(e.encode("utf-8"))

    of.close()
    sys.exit()
