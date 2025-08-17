#!/bin/bash

# bash_desqueeze_anamorphic.sh
# This script applies an anamorphic desqueeze factor to DNG files
# using exiftool, setting the DefaultScale metadata tag.
# CAUTION: It's a destructive action. This script overwrites metadata.

echo "Starting anamorphic desqueeze..."

export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

if ! command -v exiftool &> /dev/null; then
    echo "Error: exiftool not found."
    exit 1
fi

if [ "$#" -eq 0 ]; then
    echo "No DNG files provided as arguments."
    exit 1
fi

for dng_file in "$@"; do
    if [ -f "$dng_file" ]; then
        echo "Desqueezing: $dng_file"
        exiftool -DefaultScale="1 1.5" -overwrite_original "$dng_file"
        if [ $? -eq 0 ]; then
            echo "Success: $dng_file"
        else
            echo "Failed to desqueeze: $dng_file"
        fi
    else
        echo "Skipping (not found): $dng_file"
    fi
done

echo "Done."
exit 0