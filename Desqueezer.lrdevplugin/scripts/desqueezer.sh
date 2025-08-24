#!/bin/bash

# bash_desqueeze_anamorphic.sh
# This script applies an anamorphic desqueeze factor to DNG files
# using exiftool, setting the DefaultScale metadata tag.
# CAUTION: It's a destructive action. This script overwrites metadata.

echo "Starting anamorphic desqueeze..."

export PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

if ! command -v exiftool &>/dev/null; then
    echo "Error: exiftool not found."
    exit 1
fi

if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <squeezeFactor> <axis: Horizontal|Vertical> <dng files...>"
if [ "$#" -lt 3 ]; then
    echo "Usage: $0 <squeezeFactor> <axis: Horizontal|Vertical> <dng files...>"
    exit 1
fi

squeezeFactor="$1"
axis="$2"
shift 2

# Determine scale values depending on axis
if [ "$axis" = "Horizontal" ]; then
    scale="$squeezeFactor 1"
elif [ "$axis" = "Vertical" ]; then
    scale="1 $squeezeFactor"
else
    echo "Error: axis must be 'Horizontal' or 'Vertical'."
    exit 1
fi

for dng_file in "$@"; do
    if [ -f "$dng_file" ]; then
        echo "Desqueezing: $dng_file with factor $squeezeFactor on axis $axis"
        if exiftool -DefaultScale="$scale" -overwrite_original "$dng_file"; then
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
