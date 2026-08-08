#!/bin/bash

# Directory to copy dotfiles from (current Git directory)
SOURCE_DIR=$(pwd)

# Home directory
TARGET_DIR=$HOME

# Get the name of the script itself
SCRIPT_NAME=$(basename "$0")

# Expected directory for dotfile
EXPECTED_DIR="$HOME/dotfile"

# Check if the current directory is ~/dotfiles
if [[ "$SOURCE_DIR" != "$EXPECTED_DIR" ]]; then
    echo "Error: This script must be run from the ~/dotfiles directory."
    exit 1
fi

# Install required packages before copying any config
if [[ -x "$SOURCE_DIR/install.sh" ]]; then
    echo "Installing required packages..."
    bash "$SOURCE_DIR/install.sh"
else
    echo "Warning: install.sh not found next to this script, skipping package installation."
fi

# Add secret
echo "Copying secret sample..."
cp -n "$SOURCE_DIR/.secret_sample" "$HOME/.secret"
echo "Secret sample copied successfully."

echo "Copy the helix folder"
cp -rf $SOURCE_DIR/.config/helix $HOME/.config/

echo "Copy the termux folder"
cp -rf $SOURCE_DIR/.termux $HOME/

# Deploy the (empty) motd on Termux to silence the welcome banner on new sessions/boot
if [[ -n "$PREFIX" && -d "$PREFIX/etc" ]]; then
    echo "Silencing Termux welcome banner (motd)"
    cp -f "$SOURCE_DIR/.termux/motd" "$PREFIX/etc/motd"
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
                ln -sfv "$item" "$TARGET_DIR/$(basename "$item")"
            fi
        fi
    done
}

# Execute the function
echo "Setting up dotfiles..."
link_or_copy_dotfiles

# tmux switch-session script must be at ~/.tmux/ (path bound in .tmux.conf)
mkdir -p "$TARGET_DIR/.tmux"
ln -sf "$SOURCE_DIR/switch-session-fzf.sh" "$TARGET_DIR/.tmux/switch-session-fzf.sh"
echo "Linking switch-session-fzf.sh to ~/.tmux/"
echo "Dotfiles setup complete."
