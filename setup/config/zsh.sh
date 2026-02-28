#!/bin/bash

set -e

# Zsh configuration
if ! command -v zsh &> /dev/null; then
    echo "Zsh is not installed."
    echo "Installing Zsh..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt &> /dev/null; then
            sudo apt update && sudo apt install -y zsh
        elif command -v pacman &> /dev/null; then
            sudo pacman -Syu --noconfirm zsh
        else
            echo "Unsupported package manager. Please install Zsh manually."
            exit 1
        fi
    else
        echo "Unsupported OS. Please install Zsh manually."
        exit 1
    fi
fi

# Set Zsh as the default shell
if [ "$SHELL" != "$(which zsh)" ]; then
    echo "Changing default shell to Zsh..."
    chsh -s "$(which zsh)"
fi

# Install Oh My Zsh for better Zsh experience
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

