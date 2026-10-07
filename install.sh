#!/usr/bin/env bash

# Sets up a Mac from this repo: Homebrew and the Brewfile, tools with their own
# installers, the Stow links and the Claude Code plugin.
#
# Every step checks first and skips what is already done, so reruns are cheap
# and change nothing that is already in place.
#
#   ./install.sh          preflight, then do only what is missing
#   ./install.sh --check  preflight report only, change nothing

set -e

GITHUB_USERNAME="jma49"
DOTFILES_DIR="$HOME/dotfiles"
CHECK_ONLY=false
[ "${1:-}" = "--check" ] && CHECK_ONLY=true

COLOR_GREEN='\033[0;32m'
COLOR_YELLOW='\033[0;33m'
COLOR_RED='\033[0;31m'
COLOR_DIM='\033[2m'
COLOR_NC='\033[0m'

info() { printf "${COLOR_YELLOW}%s${COLOR_NC}\n" "$1"; }
success() { printf "${COLOR_GREEN}%s${COLOR_NC}\n" "$1"; }
fail() { printf "${COLOR_RED}%s${COLOR_NC}\n" "$1"; exit 1; }
# report <label> <detail when done> <detail when not> <check command...>
report() {
  local label=$1 done_detail=$2 todo_detail=$3
  shift 3
  if "$@"; then
    printf "  ${COLOR_GREEN}✓${COLOR_NC} %s ${COLOR_DIM}%s${COLOR_NC}\n" "$label" "$done_detail"
  else
    printf "  ${COLOR_YELLOW}•${COLOR_NC} %s ${COLOR_DIM}%s${COLOR_NC}\n" "$label" "$todo_detail"
  fi
}

# --- Hard requirements: stop early instead of failing halfway ----------------

[ "$(uname -s)" = Darwin ] || fail "This setup is for macOS."
[ "$(uname -m)" = arm64 ] || fail "This setup expects Apple Silicon (Homebrew in /opt/homebrew)."
[ "$(id -u)" -ne 0 ] || fail "Run as your user, not root."
if ! xcode-select -p &> /dev/null; then
  $CHECK_ONLY && fail "Xcode Command Line Tools are missing: run xcode-select --install."
  info "Installing the Xcode Command Line Tools; rerun this script when that finishes."
  xcode-select --install
  exit 1
fi
curl -fsS --max-time 10 -o /dev/null https://github.com || fail "No network: github.com is unreachable."

[ -x /opt/homebrew/bin/brew ] && eval "$(/opt/homebrew/bin/brew shellenv)"
export PATH="$HOME/.local/bin:$PATH"

# --- Checks: each answers "is this step already done?" -----------------------

have() { command -v "$1" &> /dev/null; }
repo_ok() { [ -d "$DOTFILES_DIR/.git" ]; }
# Apps already in /Applications count as installed (see preinstalled_casks)
bundle_ok() {
  [ -n "${CASK_SKIP+set}" ] || CASK_SKIP=$(preinstalled_casks | tr '\n' ' ')
  HOMEBREW_BUNDLE_CASK_SKIP="$CASK_SKIP" brew bundle check --no-upgrade --file="$DOTFILES_DIR/Brewfile" &> /dev/null
}
# A Stow package is linked when a dry run has nothing left to do
stow_ok() { [ -z "$(cd "$DOTFILES_DIR" && stow -n -v "$1" 2>&1 | grep -v 'WARNING: in simulation')" ]; }
marketplace_ok() { claude plugin marketplace list 2>/dev/null | grep -q '❯ dotfiles$'; }
plugin_ok() { claude plugin list 2>/dev/null | grep -q '❯ agent-status@dotfiles'; }
herdr_hook_ok() { herdr integration status 2>/dev/null | grep -q '^claude: current'; }

packages() { (cd "$DOTFILES_DIR" && for package in */; do echo "${package%/}"; done); }

# Casks whose app is already in /Applications but wasn't installed by Homebrew
# (installed by hand or from a DMG): brew bundle would fail on them, so skip them.
preinstalled_casks() {
  local casks
  casks=$(grep -E '^cask ' "$DOTFILES_DIR/Brewfile" | sed -E 's/cask "([^"]+)".*/\1/')
  [ -n "$casks" ] || return 0
  # shellcheck disable=SC2086
  brew info --json=v2 --cask $casks 2> /dev/null | /usr/bin/python3 -c '
import json, os, subprocess, sys
installed = set(subprocess.run(["brew", "list", "--cask", "-1"], capture_output=True, text=True).stdout.split())
for cask in json.load(sys.stdin)["casks"]:
    apps = [a for art in cask.get("artifacts", []) for a in art.get("app", []) if isinstance(a, str)]
    if cask["token"] not in installed and any(os.path.exists(f"/Applications/{a}") for a in apps):
        print(cask["token"])
'
}

# --- Preflight report ----------------------------------------------------------

echo
info "Preflight"
report "Homebrew" "installed" "will install" have brew
report "dotfiles repo" "$DOTFILES_DIR" "will clone to $DOTFILES_DIR" repo_ok
if have brew && repo_ok; then
  report "Brewfile" "everything installed" "missing packages will install" bundle_ok
fi
report "uv" "installed" "will install" have uv
report "herdr" "installed" "will install" have herdr
report "latex2text" "installed" "will install with uv" have latex2text
if have stow && repo_ok; then
  unlinked=$(packages | while read -r p; do stow_ok "$p" || printf "%s " "$p"; done)
  report "Stow links" "all packages" "will link: $unlinked" test -z "$unlinked"
else
  report "Stow links" "" "after Homebrew installs stow" false
fi
if have claude; then
  report "Claude Code plugin" "agent-status" "will install" plugin_ok
  if have herdr; then
    report "herdr Claude integration" "installed" "will install" herdr_hook_ok
  fi
else
  report "Claude Code" "" "comes with the Brewfile (npm); plugin installs on the next run" false
fi
echo

if $CHECK_ONLY; then
  info "Check only: nothing was changed."
  exit 0
fi

# --- Steps: only what the checks found missing ---------------------------------

# 1. Homebrew
if ! have brew; then
  info "Installing Homebrew..."
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/opt/homebrew/bin/brew shellenv)"
fi

# 2. This repo
if ! repo_ok; then
  info "Cloning dotfiles..."
  git clone "https://github.com/${GITHUB_USERNAME}/dotfiles.git" "$DOTFILES_DIR"
fi
cd "$DOTFILES_DIR"

# 3. Brewfile: install what's missing, never upgrade what's there
if ! bundle_ok; then
  [ -n "$CASK_SKIP" ] && info "Already in /Applications, skipping: $CASK_SKIP"
  info "Installing missing packages from the Brewfile..."
  if HOMEBREW_BUNDLE_CASK_SKIP="$CASK_SKIP" brew bundle install --no-upgrade --file="$DOTFILES_DIR/Brewfile"; then
    success "Brewfile installed."
  else
    info "Some packages failed (App Store apps need a sign-in); rerun later to retry just those."
  fi
fi

# 4. Tools with their own installers, into ~/.local/bin like on the current Mac
if ! have uv; then
  info "Installing uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh || info "uv install failed; rerun later."
fi
if ! have herdr; then
  info "Installing herdr..."
  curl -fsSL https://herdr.dev/install.sh | sh || info "herdr install failed; rerun later."
fi
# latex2text renders LaTeX in Neovim's render-markdown
if ! have latex2text && have uv; then
  uv tool install pylatexenc || info "latex2text install failed; rerun later."
fi

# 5. Stow links. Stow refuses to replace real files, and a fresh Mac already has some
# (e.g. ~/.zshrc), so back those up first; packages already linked are skipped.
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"
for package in $(packages); do
  stow_ok "$package" && continue
  while IFS= read -r file; do
    target="$HOME/${file#"$package"/}"
    if [ -f "$target" ] && [ ! -L "$target" ]; then
      mkdir -p "$BACKUP_DIR"
      mv "$target" "$BACKUP_DIR/"
      info "Backed up $target to $BACKUP_DIR"
    fi
  done < <(find "$package" -mindepth 1 -maxdepth 1 -type f ! -name '.stow-local-ignore')
  stow "$package"
  success "Linked $package"
done

# 6. Claude Code: the agent-status plugin and herdr's integration (see README)
if have claude; then
  marketplace_ok || claude plugin marketplace add "$HOME/.claude/dotfiles-plugins" || true
  plugin_ok || claude plugin install agent-status@dotfiles || true
  if have herdr && ! herdr_hook_ok; then
    herdr integration install claude || true
  fi
else
  info "claude not found yet; rerun after the Brewfile installs it to add the plugin."
fi

echo
success "Setup complete. Run ./install.sh --check any time to see what's left."
info "Restart the terminal, then work through 'After the script' in README.md (SSH keys, gh auth, secrets, sign-ins)."
echo
