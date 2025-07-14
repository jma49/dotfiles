#!/usr/bin/env bash

# This script sets up a new macOS machine by installing essential tools
# and deploying configuration files (dotfiles) managed with GNU Stow.

set -e

# --- Configuration ---
GITHUB_USERNAME="jma49"

# List of command-line tools to install via Homebrew Formulae
BREW_FORMULAE=(
  # Core Tools
  "git"
  "stow"
  "antidote"

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
)

# List of GUI Apps and Fonts to install via Homebrew Casks
BREW_CASKS=(
  "kitty"
  "font-fira-code"
  "font-maple-mono-nf"
)

# --- Script ---

COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_NC='\033[0m' # No Color

info() {
  printf "${COLOR_YELLOW}%s${COLOR_NC}\n" "$1"
}

success() {
  printf "${COLOR_GREEN}%s${COLOR_NC}\n" "$1"
}

info "Starting macOS setup..."

# 1. Install Homebrew
if ! command -v brew &> /dev/null; then
  info "Homebrew not found. Installing now..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
  success "Homebrew installed."
else
  info "Homebrew is already installed. Updating..."
  brew update
fi

# 2. Install Formulae
info "Installing formulae..."
# FIXED: Using the correct array name 'BREW_FORMULAE'
for formula in "${BREW_FORMULAE[@]}"; do
  if brew list --formula | grep -q "^${formula}\$"; then
    info "  - ${formula} is already installed. Skipping."
  else
    info "  - Installing ${formula}..."
    brew install "${formula}"
  fi
done
success "All formulae installed."

# 3. Install Casks
info "Installing casks..."
# ADDED: Loop to install casks
for cask in "${BREW_CASKS[@]}"; do
  if brew list --cask | grep -q "^${cask}\$"; then
    info "  - ${cask} is already installed. Skipping."
  else
    info "  - Installing ${cask}..."
    brew install --cask "${cask}"
  fi
done
success "All casks installed."

# 4. Clone dotfiles repository
DOTFILES_DIR="$HOME/dotfiles"
if [ ! -d "$DOTFILES_DIR" ]; then
  info "Cloning dotfiles repository..."
  git clone "https://github.com/${GITHUB_USERNAME}/dotfiles.git" "$DOTFILES_DIR"
  success "Dotfiles repository cloned."
else
  info "Dotfiles directory already exists. Skipping clone."
fi

# 5. Deploy dotfiles using GNU Stow
info "Deploying dotfiles with Stow..."
cd "$DOTFILES_DIR"
stow *
success "Dotfiles have been deployed."

echo
success "🚀 Setup complete!"
info "One last step: to make 'autojump' work, please add the following line to your '.zshrc' file:"
echo
# ADDED: Post-installation instruction for autojump
info "  [ -f \"\$(brew --prefix)/etc/profile.d/autojump.sh\" ] && . \"\$(brew --prefix)/etc/profile.d/autojump.sh\""
echo
info "After that, restart your terminal for all changes to take effect."
echo

