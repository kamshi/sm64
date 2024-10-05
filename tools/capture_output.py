#!/usr/bin/python

import subprocess
import sys

def main():
    if len(sys.argv) < 3:
        print("Usage: python capture_output.py <output_file> <command> [args...]")
        sys.exit(1)

    output_file = sys.argv[1]
    command = sys.argv[2:]

    try:
        result = subprocess.Popen(command, stderr=subprocess.PIPE)
        _, stderr = result.communicate()
        with open(output_file, 'w') as f:
            f.write(stderr.decode())
    except Exception as e:
        # this script is used to call programs which return non-zero exit codes, so this is ok
        print("An error occurred: ", str(e))

if __name__ == "__main__":
    main()
