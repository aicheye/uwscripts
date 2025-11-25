#!/bin/bash

# Submit files to Marmoset via SSH
# Usage: ./marmoset_submit.sh <course> <project> <file1> [file2] [file3] ...

# Check if we have at least 3 arguments (course, project, and at least one file)
if [ $# -lt 3 ]; then
    echo "Usage: $0 <course> <project> <file1> [file2] [file3] ..."
    echo "Example: $0 cs137 a4q1 kdigits.c"
    exit 1
fi

# SSH server details - randomly select from available servers
SERVERS=("002" "004" "008" "010" "012")
RANDOM_INDEX=$((RANDOM % ${#SERVERS[@]}))
SELECTED_SERVER=${SERVERS[$RANDOM_INDEX]}
SERVER="ubuntu2404-${SELECTED_SERVER}.student.cs.uwaterloo.ca"
REMOTE_DIR="~/tmp"

echo "Selected server: $SERVER"
echo ""

# Get course and project from arguments
COURSE="$1"
PROJECT="$2"
shift 2  # Remove first two arguments, leaving only files

# Array to store files
FILES=("$@")

# Check if all files exist locally
for file in "${FILES[@]}"; do
    if [ ! -f "$file" ]; then
        echo "Error: File '$file' not found"
        exit 1
    fi
done

echo "Course: $COURSE"
echo "Project: $PROJECT"
echo "Files: ${FILES[@]}"
echo ""

# Create remote tmp directory if it doesn't exist
echo "Creating remote tmp directory..."
ssh "$SERVER" "mkdir -p $REMOTE_DIR"

# Copy all files to the server
echo "Copying files to $SERVER:$REMOTE_DIR..."
scp "${FILES[@]}" "$SERVER:$REMOTE_DIR/"

if [ $? -ne 0 ]; then
    echo "Error: Failed to copy files to server"
    exit 1
fi

# Build the remote file paths
REMOTE_FILES=()
for file in "${FILES[@]}"; do
    filename=$(basename "$file")
    REMOTE_FILES+=("$REMOTE_DIR/$filename")
done

# Run marmoset_submit on the server
echo "Running marmoset_submit on server..."
ssh "$SERVER" "/u/cs_build/bin/marmoset_submit $COURSE $PROJECT ${REMOTE_FILES[@]}"

# Clean up tmp directory on the server
echo "Cleaning up remote tmp directory..."
ssh "$SERVER" "rm -rf $REMOTE_DIR"

echo ""
echo "Submission complete!"
