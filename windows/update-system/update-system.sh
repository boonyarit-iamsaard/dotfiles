#!/bin/zsh

# System Update Script
echo "Starting system update process..."

# 1. Update and upgrade Ubuntu/Debian packages
echo "Updating APT packages..."
sudo apt update && sudo apt upgrade -y && sudo apt autoremove && sudo apt-get clean

# 2. Update Homebrew packages
echo "Updating Homebrew packages..."
brew upgrade && brew cleanup --prune=all

# 3. Update npm global packages and clean logs
echo "Updating npm global packages..."
npm update -g

echo "Cleaning npm cache logs..."
rm -rf ~/.npm/_logs/*

echo "npm global packages update and cleanup completed"

echo "System update process finished"
