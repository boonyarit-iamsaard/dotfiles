#!/bin/zsh

# System Update Script
echo "Starting system update process..."

# Update and upgrade Ubuntu/Debian packages
echo "Updating APT packages..."
sudo apt update && sudo apt upgrade -y && sudo apt autoremove && sudo apt-get clean

# Update Homebrew packages
echo "Updating Homebrew packages..."
brew upgrade && brew cleanup --prune=all

# Check npm global packages
echo "Checking npm global packages..."
npm outdated -g
echo "npm global packages check completed"

echo "System update process finished"
