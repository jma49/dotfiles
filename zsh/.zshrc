# OPENSPEC:START
# OpenSpec shell completions configuration
fpath=("/Users/bytedance/.zsh/completions" $fpath)
autoload -Uz compinit
compinit
# OPENSPEC:END

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
if command -v brew >/dev/null 2>&1; then
  export HOMEBREW_PREFIX="$(brew --prefix)"
else
  export HOMEBREW_PREFIX="/opt/homebrew"
fi

# Java environment, if installed via Homebrew/SDKMAN or at a known path.
export JAVA_HOME="/Library/Java/JavaVirtualMachines/temurin-11.jdk/Contents/Home"
if [ -d "$JAVA_HOME" ]; then
  path+=("$JAVA_HOME/bin")
fi

# Hadoop environment, if installed via Homebrew.
export HADOOP_HOME="$HOMEBREW_PREFIX/opt/hadoop/libexec"
if [ -d "$HADOOP_HOME" ]; then
  path+=(
    "$HADOOP_HOME/bin"
    "$HADOOP_HOME/sbin"
  )
  export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
  export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"
fi

# MySQL client path, if installed via Homebrew.
if [ -d "$HOMEBREW_PREFIX/opt/mysql" ]; then
  path+=("$HOMEBREW_PREFIX/opt/mysql/bin")
fi

# PostgreSQL client path, if installed via Homebrew.
if [ -d "$HOMEBREW_PREFIX/opt/postgresql@16" ]; then
  path+=("$HOMEBREW_PREFIX/opt/postgresql@16/bin")
fi

# Finally, append the standard system paths.
path+=(
  $HOME/bin
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
export LC_ALL=en_US.UTF-8

# --- Section 2: Plugin Manager (Antidote) ---

# Source Antidote from the Homebrew path.
[ -f "$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh" ] && source "$HOMEBREW_PREFIX/opt/antidote/share/antidote/antidote.zsh"

# Initialize the Zsh completion system. This must be done before loading plugins.
autoload -U compinit
compinit -d "$HOME/.zcompdump"

# Load all plugins from the list file.
[ -f ~/.zsh_plugins.txt ] && antidote load ~/.zsh_plugins.txt

# --- Section 3: Tool Integrations ---
# Initialize tools that need to hook into the shell. This section is best kept near the end.

# Starship Prompt
eval "$(starship init zsh)"

# FZF (Fuzzy Finder) - Key bindings and completions.
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# Use `fd` as the default command for FZF for better performance.
export FZF_DEFAULT_COMMAND='fd --type f --hidden --no-ignore --follow'

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
alias lsd='lsd'

# File create and Directions
alias mkdir='mkdir -pv'   
alias rm='rm -i'          
alias cp='cp -i'            
alias mv='mv -i'

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
alias kcode='kitty --session ~/.config/kitty/claude.session'

# tns_fe_automation aliases
alias ppr='pnpm pagepass run'

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
    # Calculate the total size of the repository directory in KB
    repo_size_kb=$(du -s "$current_repository" | awk '{print $1}')
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
# Run the check once on shell startup.
check_directory_for_new_repository

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

  local size_human
  size_human=$(python3 - <<'PY' "$size_download"
import sys
n = float(sys.argv[1] or 0)
units = ['B', 'KB', 'MB', 'GB']
for unit in units:
    if n < 1024 or unit == units[-1]:
        print(f"{n:.0f}{unit}" if unit == 'B' else f"{n:.1f}{unit}")
        break
    n /= 1024
PY
)

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
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY       # Append to history, don't overwrite.
setopt SHARE_HISTORY        # Share history between all open shells.
setopt HIST_IGNORE_DUPS     # Don't record immediately repeated commands.
setopt HIST_IGNORE_SPACE    # Don't record commands that start with a space.

# --- Setcion 7: test env ---
# Configure test env
export CONSUL_HTTP_HOST=common-consul-boei18n.bytedance.net
export CONSUL_HTTP_PORT=2280

# export TEST_ENV=boei18n_prod
# export TEST_ENV=maliva
export _LEGO_WRAPPER_REGION="US"

# DUCK_AUTH_TOKEN
export DUCK_AUTH_TOKEN=amluY2hlbmcubWEvMjAyNS0wNy0xNSAxODoyOTo1Mg==

# auto_env
export API_TEST_VENV_ACTIVE=0
function auto_venv() {
  if [[ "$PWD" == *api_test* ]]; then
    if [[ $API_TEST_VENV_ACTIVE -eq 0 ]]; then
      if [ -f .venv/bin/activate ]; then
        source .venv/bin/activate
        export API_TEST_VENV_ACTIVE=1
        echo "Already activated api_test venv."
      fi
    fi
  else
    if [[ $API_TEST_VENV_ACTIVE -eq 1 ]]; then
      deactivate
      export API_TEST_VENV_ACTIVE=0
      echo "Deactivate api_test venv."
    fi
  fi
}
autoload -U add-zsh-hook
add-zsh-hook chpwd auto_venv
auto_venv

# NVM env
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion
export PATH=$HOME/.local/bin:$PATH

# OpenClaw Completion
# source "/Users/bytedance/.openclaw/completions/openclaw.zsh"

# export TAVILY_API_KEY="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"

# dev box configuration
alias k="kinit --keychain jincheng.ma@BYTEDANCE.COM"
alias dev="ssh jincheng.ma@10.251.231.47"

# zoxide configuration
eval "$(zoxide init zsh)"

# >>> ttadk completion >>>
source "$HOME/.ttadk/completion/ttadk.zsh"
# <<< ttadk completion <<<
