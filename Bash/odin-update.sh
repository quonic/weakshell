#!/usr/bin/env bash

# Installs or updates the [Odin programming language](https://odin-lang.org/) for the current user.

# Default install path: $HOME/Odin

# Usage:
#   ./odin-update.sh [install_path]

# Use default install path or first argument
_install_path="${1:-$HOME/Odin}"

# Required commands needed to install Odin
_required_commands=(
    git
    clang
    llvm-config
)

# Check if the base directory exists
if [ ! -d "$(dirname "$_install_path")" ]; then
    echo "The parent directory of $_install_path does not exist. Please create it and try again."
    exit 1
fi

# Create the path $_install_path if it doesn't exist
if ! mkdir "$_install_path"; then
    echo "Failed to create $_install_path."
    exit 1
fi

for command in "${_required_commands[@]}"; do
    if ! command -v "$command" &>/dev/null; then
        echo "$command is not installed. Please install $command and try again."
        exit 1
    fi
done

# Check if odin-lang is installed
if ! command -v odin &>/dev/null; then
    echo "Changing directory to $_install_path"
    cd "$(dirname "$_install_path")" || exit

    echo "Odin-Lang is not installed. Installing..."
    git clone https://github.com/odin-lang/Odin.git

    echo "Changing directory to Odin"
    cd Odin || exit

    echo "Building Odin"
    make && ./build_odin.sh

    echo "Adding $_install_path to PATH"
    echo "export PATH=$PATH:$PWD" >>~/.bash_profile
    cd ..

    echo "Done installing Odin"
else
    echo "Changing directory to $_install_path"
    cd "$(dirname "$_install_path")" || exit

    echo "Odin-Lang is already installed. Updating..."

    echo "Changing directory to Odin"
    cd Odin || exit

    echo "Updating Odin"
    git pull

    echo "Building Odin"
    make && ./build_odin.sh
    cd ..

    echo "Done updating Odin"
fi
