#!/bin/bash

# Directory to copy dotfiles from (current Git directory)
SOURCE_DIR=$(pwd)

# Home directory
TARGET_DIR=$HOME

# Get the name of the script itself
SCRIPT_NAME=$(basename "$0")

# Expected directory for dotfile
EXPECTED_DIR="$HOME/dotfile"

# Add secret
echo "Copying secret sample..."
cp -n "$SOURCE_DIR/.secret_sample" "$HOME/.secret"
echo "Secret sample copied successfully."

echo "Copy the helix folder"
cp -rf $SOURCE_DIR/.config/helix $HOME/.config/

echo "Copy the termux folder"
cp -rf $SOURCE_DIR/.termux $HOME/

# Check if the current directory is ~/dotfiles
if [[ "$SOURCE_DIR" != "$EXPECTED_DIR" ]]; then
    echo "Error: This script must be run from the ~/dotfiles directory."
    exit 1
fi

# Function to create symbolic links or copy directories for dotfiles
link_or_copy_dotfiles() {
    for item in "$SOURCE_DIR"/.*; do
        # Exclude .git directory, .secret* files, and the script itself
        if [[ $(basename "$item") != ".git" && ! $(basename "$item") =~ ^\.secret && \
              $(basename "$item") != "$SCRIPT_NAME" && $(basename "$item") != "." && \
              $(basename "$item") != ".." ]]; then
            if [[ -d "$item" ]]; then
                continue
            else
                # If it's a file, create a symbolic link
                echo "Creating symbolic link: $item to $TARGET_DIR/$(basename "$item")"
                ln -sv "$item" "$TARGET_DIR/$(basename "$item")"
            fi
        fi
    done
}

# Execute the function
echo "Setting up dotfiles..."
link_or_copy_dotfiles
echo "Dotfiles setup complete."
