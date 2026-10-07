#!/usr/bin/env bash

# This script sets up a new macOS machine: installs Homebrew and everything in
# the Brewfile, then deploys the dotfiles with GNU Stow.

set -e

# --- Configuration ---
GITHUB_USERNAME="jma49"
DOTFILES_DIR="$HOME/dotfiles"

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

# 2. Clone dotfiles repository
if [ ! -d "$DOTFILES_DIR" ]; then
  info "Cloning dotfiles repository..."
  git clone "https://github.com/${GITHUB_USERNAME}/dotfiles.git" "$DOTFILES_DIR"
else
  info "Dotfiles directory already exists. Skipping clone."
fi
cd "$DOTFILES_DIR"

# 3. Install everything in the Brewfile
info "Installing packages from Brewfile..."
if brew bundle install --file="$DOTFILES_DIR/Brewfile"; then
  success "All packages installed."
else
  info "Some packages failed to install; continuing. Rerun 'brew bundle' later."
fi

# Python CLI tools outside Homebrew: latex2text renders LaTeX in nvim's render-markdown
if command -v uv &> /dev/null; then
  uv tool install pylatexenc || true
else
  info "uv not found. Skipping latex2text (uv tool install pylatexenc)."
fi

# 4. Deploy dotfiles using GNU Stow (every top-level directory is a package)
info "Deploying dotfiles with Stow..."
# Stow refuses to replace real files, and a fresh Mac already has some (e.g. ~/.zshrc),
# so move any top-level file a package would link into a backup directory first.
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
for package in */; do
  package="${package%/}"
  while IFS= read -r file; do
    target="$HOME/${file#"$package"/}"
    if [ -f "$target" ] && [ ! -L "$target" ]; then
      mkdir -p "$BACKUP_DIR"
      mv "$target" "$BACKUP_DIR/"
      info "Backed up $target to $BACKUP_DIR"
    fi
  done < <(find "$package" -mindepth 1 -maxdepth 1 -type f ! -name '.stow-local-ignore')
  stow --restow "$package"
done
success "Dotfiles have been deployed."

# 5. Claude Code plugins (see README)
if command -v claude &> /dev/null; then
  info "Installing Claude Code plugins..."
  claude plugin marketplace add "$HOME/.claude/dotfiles-plugins" || true
  claude plugin install agent-status@dotfiles || true
else
  info "claude not found. Skipping Claude Code plugins."
fi

# --- Final Message ---
echo
success "🚀 Setup complete!"
info "Please restart your terminal for all changes to take full effect."
echo
