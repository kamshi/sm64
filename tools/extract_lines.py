#!/usr/bin/python3

import argparse

def extract_lines_with_prefix(file_path, prefix):
    matching_lines = []

    with open(file_path, 'r') as file:
        for line in file:
            if line.startswith(prefix):
                matching_lines.append(line.strip())  # Use strip() to remove any leading/trailing whitespace

    return matching_lines

def main():
    parser = argparse.ArgumentParser(description='Extract lines from a text file that start with a specific prefix.')
    parser.add_argument('file_path', type=str, help='Path to the text file')
    parser.add_argument('prefix', type=str, help='The prefix to search for at the beginning of the lines')

    args = parser.parse_args()

    matching_lines = extract_lines_with_prefix(args.file_path, args.prefix)

    print("Matching lines:")
    for line in matching_lines:
        print(line)

if __name__ == '__main__':
    main()
