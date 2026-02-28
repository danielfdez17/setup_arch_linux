#!/bin/bash

set -e

CURRENT_USER="$(id -un)"

run_privileged() {
    if [ "$(id -u)" -eq 0 ]; then
        "$@"
        return $?
    fi

    if ! command -v sudo >/dev/null 2>&1; then
        echo "sudo is required to install packages."
        return 1
    fi

    if sudo -n true >/dev/null 2>&1; then
        sudo "$@"
        return $?
    fi

    if [ -n "${VM_SUDO_PASS:-}" ]; then
        printf '%s\n' "$VM_SUDO_PASS" | sudo -S -p '' "$@"
        return $?
    fi

    echo "sudo requires a password. Set VM_SUDO_PASS and re-run."
    return 1
}

is_zsh_shell() {
    local shell_path="$1"
    [ -n "$shell_path" ] || return 1
    case "$shell_path" in
        */zsh) return 0 ;;
        *) return 1 ;;
    esac
}

current_login_shell() {
    getent passwd "$CURRENT_USER" | cut -d: -f7
}

# Zsh configuration
if ! command -v zsh &> /dev/null; then
    echo "Zsh is not installed."
    echo "Installing Zsh..."
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt &> /dev/null; then
            run_privileged apt update
            run_privileged apt install -y zsh
        elif command -v pacman &> /dev/null; then
            run_privileged pacman -Syu --noconfirm zsh
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
ZSH_PATH="$(command -v zsh)"
CURRENT_SHELL="$(current_login_shell)"

if ! is_zsh_shell "$CURRENT_SHELL"; then
    echo "Changing default shell to Zsh..."
    if chsh -s "$ZSH_PATH" "$CURRENT_USER" >/dev/null 2>&1; then
        :
    elif command -v sudo >/dev/null 2>&1 && sudo -n chsh -s "$ZSH_PATH" "$CURRENT_USER" >/dev/null 2>&1; then
        :
    else
        echo "Could not change default shell automatically. Run: chsh -s $ZSH_PATH"
    fi
fi

# Install Oh My Zsh for better Zsh experience
if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
fi

