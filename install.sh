#!/usr/bin/env bash

# This script sets up a new macOS machine by installing essential tools
# and deploying configuration files (dotfiles) managed with GNU Stow.

# Exit immediately if a command exits with a non-zero status.
set -e

# --- Configuration ---
# Your GitHub username.
# IMPORTANT: Change this to your actual GitHub username.
GITHUB_USERNAME="jma49"

# List of applications to install via Homebrew.
BREW_FORMULAE=(
  # Core Tools
  "git"
  "stow"

  # Main Applications
  "neovim"
  "yazi"
  "htop"
  "starship"

  # Neovim Enhancements (for plugins like Telescope/fzf)
  "fd"
  "fzf"
  "ripgrep"
  "lazygit"

  # File Preview Enhancements (for Yazi)
  "bat"
  "poppler"
  "lsd"

  # General CLI Utilities
  "autojump"
  "glow"
  "tree"
  "fastfetch"
  ""
)

# List of GUI Apps and Fonts to install via Homebrew Casks
BREW_CASKS=(
  "kitty"
  "font-fira-code" # A popular font for programming
  "font-maple-mono-nf" # You use Maple Mono NF, which is great for icons
)

# --- Script ---

# Define some colors for output
COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_NC='\033[0m' # No Color

# Helper function for logging
info() {
  printf "${COLOR_YELLOW}%s${COLOR_NC}\n" "$1"
}

success() {
  printf "${COLOR_GREEN}%s${COLOR_NC}\n" "$1"
}

# --- Main Logic ---

info "Starting macOS setup..."

# 1. Install Homebrew (if not already installed)
if ! command -v brew &> /dev/null; then
  info "Homebrew not found. Installing now..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  # Add Homebrew to PATH for this script's session
  eval "$(/opt/homebrew/bin/brew shellenv)"
  success "Homebrew installed."
else
  info "Homebrew is already installed. Skipping."
fi

# 2. Install packages from the list using Homebrew
info "Installing core packages and applications..."
for package in "${BREW_PACKAGES[@]}"; do
  if brew list --formula | grep -q "^${package}\$"; then
    info "  - ${package} is already installed. Skipping."
  else
    info "  - Installing ${package}..."
    brew install "${package}"
  fi
done
success "All packages installed."

# 3. Clone dotfiles repository (if it doesn't exist)
DOTFILES_DIR="$HOME/dotfiles"
if [ ! -d "$DOTFILES_DIR" ]; then
  info "Cloning dotfiles repository..."
  git clone "https://github.com/${GITHUB_USERNAME}/dotfiles.git" "$DOTFILES_DIR"
  success "Dotfiles repository cloned to ${DOTFILES_DIR}"
else
  info "Dotfiles directory already exists. Skipping clone."
fi

# 4. Deploy dotfiles using GNU Stow
info "Deploying dotfiles with Stow..."
cd "$DOTFILES_DIR"
# The '*' will expand to all top-level directories (nvim, kitty, etc.)
stow *
success "Dotfiles have been deployed."

# --- Final Message ---
echo
success "🚀 Setup complete!"
info "Please restart your terminal or source your shell configuration for all changes to take effect."
echo
