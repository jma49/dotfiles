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

# Java environment, if installed via Homebrew/SDKMAN or at a known path.
export JAVA_HOME="/Library/Java/JavaVirtualMachines/temurin-11.jdk/Contents/Home"
if [ -d "$JAVA_HOME" ]; then
  path+=("$JAVA_HOME/bin")
fi

# Hadoop environment, if installed via Homebrew.
export HADOOP_HOME="$(brew --prefix)/opt/hadoop/libexec"
if [ -d "$HADOOP_HOME" ]; then
  path+=(
    "$HADOOP_HOME/bin"
    "$HADOOP_HOME/sbin"
  )
  export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
  export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"
fi

# MySQL client path, if installed via Homebrew.
if [ -d "$(brew --prefix)/opt/mysql" ]; then
  path+=("$(brew --prefix)/opt/mysql/bin")
fi

# PostgreSQL client path, if installed via Homebrew.
if [ -d "$(brew --prefix)/opt/postgresql@16" ]; then
  path+=("$(brew --prefix)/opt/postgresql@16/bin")
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
[ -f "$(brew --prefix)/opt/antidote/share/antidote/antidote.zsh" ] && source "$(brew --prefix)/opt/antidote/share/antidote/antidote.zsh"

# Initialize the Zsh completion system. This must be done before loading plugins.
autoload -U compinit && compinit

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
alias ...= 'cd ../..'
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
alias ping='ping -c 5'   
alias myip='curl ifconfig.me'

# Other Useful Aliases
alias c='clear'            
alias h='history'         
alias path='echo $PATH | tr ":" "\n"'  
alias reload='source ~/.zshrc'

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

# Wrap the builtin 'cd' command to trigger the check.
cd() {
 builtin cd "$@"
 check_directory_for_new_repository
}
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
