#!/bin/zsh
# -----------------------------------------------------------------------------
# .zshrc - A clean, fast, modular, and intelligent Zsh configuration.
#
# Author: Jincheng Ma
# Last Updated: July 13, 2025
# -----------------------------------------------------------------------------

# --- Section 1: Environment & PATH Configuration ---

# Load local secrets from ~/.local_secrets if the file exists.
# This file is ignored by Git and should contain sensitive environment variables.
[ -f ~/.local_secrets ] && source ~/.local_secrets

# Manage PATH using an array for clarity, control, and to prevent duplicates.
# The `typeset -U path` command ensures that each entry is unique.
typeset -U path
path=(
  # Homebrew should be first to take precedence over system binaries.
  /opt/homebrew/sbin
  /opt/homebrew/bin
)

# --- Conditionally Loaded Environments ---
# Only add paths and environment variables for software that is actually installed.

# Brew auto update config
export HOMEBREW_AUTO_UPDATE_SECS=86400
# Apple Silicon prefix; hardcoded to avoid a `brew --prefix` subprocess per shell
export HOMEBREW_PREFIX="/opt/homebrew"

# User-installed CLIs (herdr, claude, ...)
path=($HOME/.local/bin $path)

# Finally, append the standard system paths.
path+=(
  /usr/local/bin
  /usr/bin
  /bin
  /usr/sbin
  /sbin
)

# --- General Environment Variables ---

# Set the default editor for command-line tools.
export EDITOR='nvim'
export VISUAL='nvim'

# Set the locale to prevent issues with character encoding.
export LANG=en_US.UTF-8

# --- Section 2: Plugin Manager (Antidote) ---

# Source Antidote from the Homebrew path.
[ -f "$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh" ] && source "$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh"

# Load all plugins from the list file.
[ -f ~/.zsh_plugins.txt ] && antidote load ~/.zsh_plugins.txt

# Initialize the Zsh completion system after plugins, so completion definitions
# they add to fpath (zsh-completions) get registered.
# Rebuild the cache at most once a day; otherwise load it and skip the security check.
autoload -Uz compinit
() {
  if (( $# )); then
    compinit -d "$HOME/.zcompdump"
  else
    compinit -C -d "$HOME/.zcompdump"
  fi
} "$HOME"/.zcompdump(N.mh+24)

# --- Section 3: Tool Integrations ---
# Initialize tools that need to hook into the shell. This section is best kept near the end.

# Vi keys on the command line, like nvim. zsh already picked vi because $EDITOR
# is nvim; set it explicitly so it doesn't hinge on $EDITOR.
bindkey -v
KEYTIMEOUT=1  # Esc reaches normal mode in 10ms instead of 400ms
# Let Backspace and Ctrl-W delete past where insert mode began (vim-like)
bindkey -M viins '^?' backward-delete-char '^H' backward-delete-char '^W' backward-kill-word
# Cursor shape follows the mode: beam in insert, block in normal. Defined before
# starship init, which wraps an existing zle-keymap-select to redraw its prompt.
_vi_cursor_shape() { [[ $KEYMAP == vicmd ]] && print -n '\e[2 q' || print -n '\e[6 q' }
zle-keymap-select() { _vi_cursor_shape }
zle-line-init() { _vi_cursor_shape }
zle -N zle-keymap-select
zle -N zle-line-init

# Starship Prompt
eval "$(starship init zsh)"

# FZF (Fuzzy Finder) - Key bindings and completions.
command -v fzf >/dev/null && source <(fzf --zsh)
# Use `fd` as the default command for FZF; hidden files yes, .git and ignored files no.
export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
# Catppuccin Mocha colors
export FZF_DEFAULT_OPTS=" \
--color=bg+:#313244,bg:-1,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a,border:#6c7086,label:#cdd6f4 \
--border=rounded"
# Previews: file contents for Ctrl-T, a directory tree for Alt-C
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 {}'"
export FZF_ALT_C_OPTS="--preview 'lsd --tree --depth 2 --color=always --icon=always {}'"

# Alt-J: jump to a project (dotfiles, ~/Code, ~/Code/personal, ~/.config) with a
# tree preview; complements zoxide, which only knows directories already visited
fzf-project-widget() {
  local dir
  dir=$( { print -r -- ~/dotfiles; fd --type d --max-depth 1 --absolute-path . ~/Code ~/Code/personal ~/.config 2>/dev/null; } |
    fzf --height=60% --reverse --prompt='project> ' \
      --preview 'lsd --tree --depth 2 --color=always --icon=always {}') || { zle reset-prompt; return }
  # Run the cd as a command so prompt and chpwd hooks behave as if typed
  BUFFER="builtin cd -- ${(q)dir}"
  zle accept-line
}
zle -N fzf-project-widget
bindkey '\ej' fzf-project-widget

# SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "$SDKMAN_DIR/bin/sdkman-init.sh"


# --- Section 4: Aliases ---
# Personal command shortcuts for efficiency.

# Navigation
alias ..='cd ..'
alias ...='cd ../..'
alias home='cd ~'
alias ls='lsd'                 
alias ll='lsd -l'             
alias la='lsd -a'              
alias lla='lsd -la'            
alias lt='lsd --tree'         

# File create and Directions
alias mkdir='mkdir -pv'   
if [[ -z "$CLAUDECODE" ]]; then
  alias rm='rm -i'
  alias cp='cp -i'
  alias mv='mv -i'
fi

# System Tools
# alias cat='bat' # Use `bat` instead of `cat` for syntax highlighting.
# alias c++='g++-14'
# alias gcc='gcc-14'

# Git Aliases
alias g='git'
alias gc='git clone'
alias ga='git add'
alias gaa='git add .'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gcsm='git commit -s -m'
alias gs='git status'
alias gp='git push'
alias gpl='git pull'
alias gl='git log --oneline --graph --decorate'
alias gpristine='git reset --hard && git clean -dffx'

# Net related
alias ping='ping -c 10'   
alias myip='curl ifconfig.me'

# Other Useful Aliases
alias c='clear'
alias h='history'
alias path='echo $PATH | tr ":" "\n"'
alias reload='source ~/.zshrc'

# --- Section 5: Custom Functions ---
# More complex custom commands.

# Greeter: Run 'onefetch' when entering a small new git repository.
last_repository=
MAX_SIZE_KB=524288  # 512MB = 512 * 1024 KB
check_directory_for_new_repository() {
  # Get the top-level directory of the current git repository
  current_repository=$(git rev-parse --show-toplevel 2> /dev/null)
  # If inside a git repo and it's a new repo compared to the last checked
  if [ "$current_repository" ] && [ "$current_repository" != "$last_repository" ]; then
    # Size of the git object store (loose + packed, in KB): instant, unlike
    # walking the work tree with du, which also counts node_modules
    repo_size_kb=$(git count-objects -v | awk '$1 == "size:" || $1 == "size-pack:" { kb += $2 } END { print kb + 0 }')
    # Only run onefetch if the repo size is less than or equal to the threshold
    if [ "$repo_size_kb" -le "$MAX_SIZE_KB" ]; then
      onefetch
    else
      echo "Skipped large repository ($(($repo_size_kb / 1024)) MB): $current_repository"
    fi
  fi
  # Update the last repository variable
  last_repository=$current_repository
}
autoload -U add-zsh-hook
add-zsh-hook chpwd check_directory_for_new_repository
# Remember the repo the shell starts in, so onefetch only shows after cd-ing into another one.
last_repository=$(git rev-parse --show-toplevel 2> /dev/null)

# Yazi integration: Open Yazi with 'y', and cd to the last directory on exit.
function y() {
    local tmp
    tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    # shellcheck disable=SC2164
    if IFS= read -r -d '' cwd < "$tmp"; then
        if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            cd -- "$cwd"
        fi
    fi
    rm -f -- "$tmp"
}

# Pretty-print JSON responses in interactive shells without breaking common curl workflows.
curl() {
  emulate -L zsh
  setopt local_options no_aliases pipe_fail

  if [[ -n "${CURL_RAW:-}" || ! -t 1 ]]; then
    command curl "$@"
    return $?
  fi

  local arg
  local passthrough=0
  local next_takes_path=0

  for arg in "$@"; do
    if (( next_takes_path )); then
      passthrough=1
      next_takes_path=0
      continue
    fi

    case "$arg" in
      -o|--output|-D|--dump-header)
        passthrough=1
        next_takes_path=1
        ;;
      -O|--remote-name|-I|--head|-i|--include|-v|--verbose|--trace|--trace-*|-#|--progress-bar|-w|--write-out)
        passthrough=1
        ;;
    esac
  done

  if (( passthrough )); then
    command curl "$@"
    return $?
  fi

  local body_file header_file meta_file stderr_file curl_exit=0
  body_file="$(mktemp)"
  header_file="$(mktemp)"
  meta_file="$(mktemp)"
  stderr_file="$(mktemp)"

  command curl -sS -D "$header_file" -o "$body_file" -w '%{http_code}\n%{content_type}\n%{url_effective}\n%{remote_ip}\n%{size_download}\n%{time_total}\n%{errormsg}\n' "$@" > "$meta_file" 2> "$stderr_file"
  curl_exit=$?

  local -a meta
  meta=("${(@f)$(<"$meta_file")}")

  local http_code="${meta[1]:-000}"
  local content_type="${meta[2]:-}"
  local url_effective="${meta[3]:-}"
  local remote_ip="${meta[4]:-}"
  local size_download="${meta[5]:-0}"
  local time_total="${meta[6]:-0}"
  local errormsg="${meta[7]:-}"
  local content_type_base="${content_type%%;*}"

  local status_color dim_color reset_color bold_color
  reset_color=$'\033[0m'
  dim_color=$'\033[2m'
  bold_color=$'\033[1m'
  if [[ "$http_code" == 2* || "$http_code" == 3* ]]; then
    status_color=$'\033[32m'
  elif [[ "$http_code" == 4* ]]; then
    status_color=$'\033[33m'
  else
    status_color=$'\033[31m'
  fi

  local size_human unit
  local -F 1 size=${size_download:-0}
  if (( size < 1024 )); then
    size_human="${size_download:-0}B"
  else
    for unit in KB MB GB; do
      (( size /= 1024 ))
      (( size < 1024 )) || [[ $unit == GB ]] && break
    done
    size_human="${size}${unit}"
  fi

  if [[ -n "$url_effective" ]]; then
    print -u2 -- "${bold_color}${status_color}HTTP ${http_code}${reset_color} ${content_type_base:-unknown} ${dim_color}${time_total}s ${size_human}${${remote_ip:+ from ${remote_ip}}}${reset_color}"
    print -u2 -- "${dim_color}${url_effective}${reset_color}"
  else
    print -u2 -- "${bold_color}${status_color}curl exit ${curl_exit}${reset_color}${${errormsg:+ ${errormsg}}}"
  fi

  local is_json=0
  if [[ -s "$body_file" ]] && jq . < "$body_file" >/dev/null 2>&1; then
    is_json=1
  fi

  if (( is_json )) && [[ "$http_code" != 2* && "$http_code" != 3* ]]; then
    local error_summary
    error_summary=$(jq -r '
      [
        .message?,
        .error?,
        .detail?,
        .title?,
        (if (.status_code? // .code? // .status?) then "code=" + ((.status_code? // .code? // .status?) | tostring) else empty end)
      ]
      | map(select(type == "string" and length > 0))
      | unique
      | join(" | ")
    ' < "$body_file" 2>/dev/null)

    if [[ -n "$error_summary" ]]; then
      print -u2 -- "${status_color}${error_summary}${reset_color}"
    fi
  fi

  if [[ -s "$body_file" ]]; then
    if (( is_json )); then
      if command -v bat >/dev/null 2>&1; then
        jq . < "$body_file" | bat --language=json --style=plain --paging=auto
      else
        jq -C . < "$body_file" | less -RFX
      fi
    else
      cat "$body_file"
    fi
  fi

  if [[ -s "$stderr_file" ]]; then
    cat "$stderr_file" >&2
  fi

  if (( curl_exit != 0 )) && [[ -n "$errormsg" ]]; then
    print -u2 -- "$errormsg"
  fi

  command rm -f -- "$body_file" "$header_file" "$meta_file" "$stderr_file"
  return $curl_exit
}


# --- Section 6: History Configuration ---
# Configure Zsh's command history behavior.
HISTFILE=~/.zsh_history
HISTSIZE=100000
SAVEHIST=100000
setopt APPEND_HISTORY       # Append to history, don't overwrite.
setopt SHARE_HISTORY        # Share history between all open shells.
setopt EXTENDED_HISTORY     # Record when each command ran and how long it took.
setopt HIST_IGNORE_ALL_DUPS # Keep only the latest copy of a repeated command.
setopt HIST_IGNORE_SPACE    # Don't record commands that start with a space.

# OpenClaw Completion
# source "$HOME/.openclaw/completions/openclaw.zsh"

# zoxide configuration
eval "$(zoxide init zsh)"

