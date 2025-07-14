#!/usr/bin/env bash

# This script sets up a new macOS machine by installing essential tools
# and deploying configuration files (dotfiles) managed with GNU Stow.

set -e

# --- Configuration ---
GITHUB_USERNAME="jma49"

# List of command-line tools to install via Homebrew Formulae
BREW_FORMULAE=(
  "git"
  "stow"
  "antidote"
  "neovim"
  "yazi"
  "htop"
  "starship"
  "fd"
  "fzf"
  "ripgrep"
  "lazygit"
  "bat"
  "poppler"
  "lsd"
  "autojump"
  "glow"
  "tree"
  "fastfetch"
  "onefetch"
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
else
  info "Homebrew is already installed. Updating..."
  brew update
fi

# 2. Set Zsh as the default shell (recommended)
ZSH_PATH="$(brew --prefix)/bin/zsh"
if [ "$SHELL" != "$ZSH_PATH" ]; then
  info "Changing default shell to Homebrew Zsh..."
  # Add Homebrew's Zsh to the list of allowed shells
  if ! grep -q "$ZSH_PATH" /etc/shells; then
    echo "$ZSH_PATH" | sudo tee -a /etc/shells
  fi
  chsh -s "$ZSH_PATH"
  success "Default shell changed to Zsh. Please enter your password if prompted."
else
  info "Homebrew Zsh is already the default shell."
fi

# 3. Install Formulae
info "Installing formulae..."
for formula in "${BREW_FORMULAE[@]}"; do
  if brew list --formula | grep -q "^${formula}\$"; then
    info "  - ${formula} is already installed. Skipping."
  else
    info "  - Installing ${formula}..."
    brew install "${formula}"
  fi
done
success "All formulae installed."

# 4. Install Casks
info "Installing casks..."
for cask in "${BREW_CASKS[@]}"; do
  if brew list --cask | grep -q "^${cask}\$"; then
    info "  - ${cask} is already installed. Skipping."
  else
    info "  - Installing ${cask}..."
    brew install --cask "${cask}"
  fi
done
success "All casks installed."

# 5. Clone dotfiles repository
DOTFILES_DIR="$HOME/dotfiles"
if [ ! -d "$DOTFILES_DIR" ]; then
  info "Cloning dotfiles repository..."
  git clone "https://github.com/${GITHUB_USERNAME}/dotfiles.git" "$DOTFILES_DIR"
else
  info "Dotfiles directory already exists. Skipping clone."
fi

# 6. Deploy dotfiles using GNU Stow
info "Deploying dotfiles with Stow..."
cd "$DOTFILES_DIR"
stow *
success "Dotfiles have been deployed."

# --- Final Message ---
echo
success "🚀 Setup complete!"
info "Please restart your terminal for all changes to take full effect."
echo
