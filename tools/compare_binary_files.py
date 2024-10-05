#!/usr/bin/python3

import os
import fnmatch
import argparse

def compare_files(file1, file2):
    with open(file1, 'rb') as f1, open(file2, 'rb') as f2:
        chunk_size = 4096
        while True:
            b1 = f1.read(chunk_size)
            b2 = f2.read(chunk_size)
            if b1 != b2:
                return False
            if not b1:  # Reached the end of both files
                return True

def find_unique_elements(list1, list2):
    set1 = set(list1)
    set2 = set(list2)

    only_list1 = set1 - set2
    only_list2 = set2 - set1
    common_elements = set1 & set2

    return list(common_elements), list(only_list1), list(only_list2)

def find_files(directory, extension):
    matches = []
    for root, _, filenames in os.walk(directory):
        for filename in fnmatch.filter(filenames, f'*.{extension}'):
            matches.append(os.path.join(root, filename))
    return matches

def main():
    parser = argparse.ArgumentParser(description='Recursively find files with a specific extension in a directory.')
    parser.add_argument('directory', type=str, help='The directory to compare with the reference directory')
    parser.add_argument('reference_dir', type=str, help='The directory to compare to')
    parser.add_argument('extension', type=str, help='The file extension to look for (e.g., txt)')

    args = parser.parse_args()

    files = find_files(args.directory, args.extension)
    referenceFiles = find_files(args.reference_dir, args.extension)

    for i in range(len(files)):
        files[i] = os.path.relpath(files[i], args.directory)

    for i in range(len(referenceFiles)):
        referenceFiles[i] = os.path.relpath(referenceFiles[i], args.reference_dir)

    commonFiles, additionalFiles, missingFiles = find_unique_elements(files, referenceFiles)

    # list files which are missing
    if len(missingFiles) > 0:
        print("The following files exist in the reference directory but are missing")
        for file in missingFiles:
            print("    " + file)

    # list files which differ from the reference files
    for file in commonFiles:
        #print(os.path.join(args.directory, file))
        #print(os.path.join(args.reference_dir, file))
        if not compare_files(os.path.join(args.directory, file), os.path.join(args.reference_dir, file)):
            print("File mismatch: " + file)
        else:
            print("Files equal: " + file)

if __name__ == '__main__':
    main()
