#!/bin/zsh
# -----------------------------------------------------------------------------
# .zshrc - 一个整洁、快速、模块化的 Zsh 配置文件
# -----------------------------------------------------------------------------

# --- 第1节：环境变量与PATH路径 ---
# 首先加载密钥文件，这样后续的工具就能使用这些变量
[ -f ~/.local_secrets ] && source ~/.local_secrets

export PATH="/opt/homebrew/bin"
export PATH="$PATH:/opt/homebrew/sbin"

# Java
export JAVA_HOME="/Library/Java/JavaVirtualMachines/temurin-11.jdk/Contents/Home"
export PATH="$PATH:$JAVA_HOME/bin"

# Hadoop
export HADOOP_HOME="/opt/homebrew/Cellar/hadoop/3.3.6/libexec"
export PATH="$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin"

# MySQL & PostgreSQL
export PATH="$PATH:/opt/homebrew/opt/mysql/bin"
export PATH="$PATH:/opt/homebrew/opt/postgresql@16/bin"

# 最后，追加系统默认的 PATH 路径
export PATH="$PATH:$HOME/bin:/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"


# 设置默认编辑器
export EDITOR='nvim'
export VISUAL='nvim'

# 设置语言环境，防止乱码
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# Hadoop 相关的特定变量
export HADOOP_CONF_DIR="$HADOOP_HOME/etc/hadoop"
export HADOOP_OPTS="-Djava.library.path=$HADOOP_HOME/lib/native"


# --- 第2节：Antidote 插件管理器 ---
# Source Antidote from the Homebrew path
[ -f "$(brew --prefix)/opt/antidote/share/antidote/antidote.zsh" ] && source "$(brew --prefix)/opt/antidote/share/antidote/antidote.zsh"

autoload -U compinit && compinit

# Load all plugins from our list file
[ -f ~/.zsh_plugins.txt ] && antidote load ~/.zsh_plugins.txt 

# --- 第3节：工具集成 ---
# 这是让 starship, fzf, sdkman 等工具与 Shell 挂钩的地方
# 这一部分应该靠近文件的末尾

# Starship 提示符
eval "$(starship init zsh)"

# FZF (模糊搜索器)
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
export FZF_DEFAULT_COMMAND='fd --type f --hidden --no-ignore --follow'

# SDKMAN
export SDKMAN_DIR="$HOME/.sdkman"
[ -s "$SDKMAN_DIR/bin/sdkman-init.sh" ] && source "$SDKMAN_DIR/bin/sdkman-init.sh"


# --- 第4节：命令别名 (Aliases) ---
alias ..='cd ..'
alias c++='g++-14'
alias gcc='gcc-14'
alias cat='bat'

# Git 别名
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


# --- 第5节：自定义函数 ---

# 'cd' 进入一个目录后，如果是新的 git 仓库，就运行 'onefetch'
last_repository=
check_directory_for_new_repository() {
 current_repository=$(git rev-parse --show-toplevel 2> /dev/null)
 if [ "$current_repository" ] && [ "$current_repository" != "$last_repository" ]; then
  onefetch
 fi
 last_repository=$current_repository
}
# 包装原始的 'cd' 命令
cd() {
 builtin cd "$@"
 check_directory_for_new_repository
}
# shell 启动时也检查一次
check_directory_for_new_repository

# Yazi 集成: 使用 'y' 打开 yazi, 退出时自动 'cd' 到所在目录
function y() {
    local tmp="$(mktemp -t "yazi-cwd.XXXXXX")"
    yazi "$@" --cwd-file="$tmp"
    if IFS= read -r -d '' cwd < "$tmp"; then
        if [ -n "$cwd" ] && [ "$cwd" != "$PWD" ]; then
            cd -- "$cwd"
        fi
    fi
    rm -f -- "$tmp"
}


# --- 第6节：历史记录设置 (History) ---
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt APPEND_HISTORY SHARE_HISTORY HIST_IGNORE_DUPS HIST_IGNORE_SPACE
