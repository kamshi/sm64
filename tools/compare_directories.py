#!/usr/bin/python3
import os
import argparse

def generate_file_list(root_dir, output_file):
    with open(output_file, 'w') as f:
        for dirpath, _, filenames in os.walk(root_dir):
            for filename in filenames:
                file_path = os.path.relpath(os.path.join(dirpath, filename), root_dir)
                f.write(file_path + '\n')

def read_file_list(file_path):
    with open(file_path, 'r') as f:
        return set(line.strip() for line in f)

def compare_file_lists(original_file, current_dir):
    original_files = read_file_list(original_file)
    current_files = set()
    
    for dirpath, _, filenames in os.walk(current_dir):
        for filename in filenames:
            file_path = os.path.relpath(os.path.join(dirpath, filename), current_dir)
            current_files.add(file_path)
    
    created_files = current_files - original_files
    removed_files = original_files - current_files
    
    return created_files, removed_files

def main():
    parser = argparse.ArgumentParser(description='Track changes in directory contents.')
    parser.add_argument('directory', help='The directory to monitor.')
    parser.add_argument('--output', default='file_list.txt', help='The output file to store the list of files.')
    parser.add_argument('--regenerate', action='store_true', help='Regenerate the file list.')

    args = parser.parse_args()
    directory = args.directory
    output_file = args.output
    regenerate = args.regenerate

    if regenerate or not os.path.exists(output_file):
        generate_file_list(directory, output_file)
        print(f'File list generated and stored in {output_file}')
    else:
        created, removed = compare_file_lists(output_file, directory)
        if created:
            print("Created files:")
            for file in created:
                print(file)
        else:
            print("No new files created.")
        
        if removed:
            print("\nRemoved files:")
            for file in removed:
                print(file)
        else:
            print("No files removed.")

if __name__ == '__main__':
    main()
