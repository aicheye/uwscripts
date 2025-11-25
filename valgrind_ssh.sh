#!/bin/bash

# Submit files to Valgrind via SSH
# Usage: ./valgrind_ssh.sh <file>

# Check if we have one argument
if [ $# -ne 1 ]; then
    echo "Usage: $0 <file>"
    echo "Example: $0 kdigits.c"
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

# Get file from arguments
FILE="$1"

# Check if the file exists locally
if [ ! -f "$FILE" ]; then
    echo "Error: File '$FILE' not found"
    exit 1
fi

echo "Selected file: $FILE"
echo ""

# Create remote tmp directory if it doesn't exist
echo "Creating remote tmp directory..."
ssh "$SERVER" "mkdir -p $REMOTE_DIR"

# Copy the file to the server
echo "Copying file to $SERVER:$REMOTE_DIR..."
scp "$FILE" "$SERVER:$REMOTE_DIR/"

if [ $? -ne 0 ]; then
    echo "Error: Failed to copy file to server"
    exit 1
fi

# Build the remote file path
REMOTE_FILE="$REMOTE_DIR/$(basename "$FILE")"

# Run Valgrind on the server
echo "Running Valgrind on server..."
ssh "$SERVER" "valgrind --leak-check=full --show-leak-kinds=all $REMOTE_FILE"

# Clean up tmp directory on the server
echo "Cleaning up remote tmp directory..."
ssh "$SERVER" "rm -rf $REMOTE_DIR"

echo ""
echo "Valgrind analysis complete!"
