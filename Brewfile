# Homebrew bundle: `brew bundle install` installs it all; keep it in sync with
# `brew bundle dump`. Dependencies Homebrew pulls in on its own are left out.

tap "fwartner/tap", trusted: true
tap "supabase/tap"

# --- Shell and prompt ---
brew "antidote"  # Plugin manager for zsh, inspired by antigen and antibody
brew "starship"  # Cross-shell prompt for astronauts
brew "zoxide"  # Shell extension to navigate your filesystem faster
brew "fzf"  # Command-line fuzzy finder written in Go
brew "fd"  # Simple, fast and user-friendly alternative to find
brew "ripgrep"  # Search tool like grep and The Silver Searcher
brew "bat"  # Clone of cat(1) with syntax highlighting and Git integration
brew "lsd"  # Clone of ls with colorful output, file type icons, and more
brew "tree"  # Display directories as trees (with optional color/HTML output)
brew "stow"  # Organize software neatly under a single directory tree (e.g. /usr/local)
brew "jq"  # Lightweight and flexible command-line JSON processor
brew "dos2unix"  # Convert text between DOS, UNIX, and Mac formats
brew "wget"  # Internet file retriever
brew "lsof"  # Utility to list open files

# --- Git ---
brew "git"  # Distributed revision control system
brew "git-delta"  # Syntax-highlighting pager for git and diff output
brew "gh"  # GitHub command-line tool
brew "lazygit"  # Simple terminal UI for git commands
brew "git-filter-repo"  # Quickly rewrite git repository history
brew "onefetch"  # Command-line Git information tool

# --- Editors and linters ---
brew "neovim"  # Ambitious Vim-fork focused on extensibility and agility
brew "tree-sitter-cli"  # Parser generator tool
brew "shellcheck"  # Static analysis for shell scripts (CI lint)
brew "stylua"  # Lua formatter (CI lint, nvim config)
brew "taplo"  # TOML formatter and linter (CI lint)
brew "gitleaks"  # Secret scanner (CI; run `gitleaks git` before pushing)
brew "mas"  # Mac App Store CLI, installs the mas entries below

# --- Languages and runtimes ---
brew "node"  # Open-source, cross-platform JavaScript runtime environment
brew "go"  # Open source programming language to build simple/reliable/efficient software
brew "gcc"  # GNU compiler collection
brew "pkgconf"  # Package compiler and linker metadata toolkit
brew "openjdk"  # Development kit for the Java programming language
brew "maven"  # Java-based project management
brew "poetry"  # Python package management tool

# --- Cloud, databases and APIs ---
brew "vercel"  # Command-line interface for Vercel
brew "supabase/tap/supabase"  # Supabase CLI
brew "helm"  # Kubernetes package manager
brew "kubernetes-cli"  # Kubernetes command-line interface
brew "postgresql@17"  # Object-relational database system
brew "grpcurl"  # Like cURL, but for gRPC

# --- Docs and media rendering (nvim, yazi) ---
brew "glow"  # Render markdown on the CLI
brew "imagemagick"  # Tools and libraries to manipulate images in select formats
brew "ghostscript"  # Interpreter for PostScript and PDF
brew "tectonic"  # Modernized, complete, self-contained TeX/LaTeX engine
brew "mermaid-cli"  # CLI for Mermaid library
brew "ffmpeg"  # Play, record, convert, and stream select audio and video codecs
brew "yt-dlp"  # Feature-rich command-line audio/video downloader

# --- System monitoring and cleanup ---
brew "btop"  # Resource monitor. C++ version and continuation of bashtop and bpytop
brew "bottom"  # Yet another cross-platform graphical process/system monitor
brew "dust"  # More intuitive version of du in rust
brew "gdu"  # Disk usage analyzer with console interface written in Go
brew "fastfetch"  # Like neofetch, but much faster because written mostly in C
brew "fwartner/tap/mac-cleanup", trusted: true  # 🗑️ cleanup script for macos
brew "mole"  # Deep clean and optimize your Mac

# --- File manager ---
brew "yazi"  # Blazing fast terminal file manager written in Rust, based on async I/O

# --- Terminal and editors ---
cask "kitty"  # GPU-based terminal emulator
cask "zed"  # Multiplayer code editor
cask "cursor"  # Write, edit, and chat about your code with AI
cask "codex"  # OpenAI's coding agent that runs in your terminal
cask "typora"  # Configurable document editor that supports Markdown

# --- Development ---
cask "orbstack"  # Replacement for Docker Desktop
cask "gcloud-cli"  # Set of tools to manage resources and applications hosted on Google Cloud
cask "android-studio"  # Tools for building Android applications
cask "android-platform-tools"  # Android SDK component
cask "mitmproxy"  # Intercept, modify, replay, save HTTP/S traffic
cask "macfuse"  # File system integration
cask "postman"  # Collaboration platform for API development

# --- Browsers and AI apps ---
cask "google-chrome"  # Web browser
cask "firefox"  # Web browser
cask "chatgpt"  # OpenAI's official ChatGPT desktop app
cask "claude"  # Anthropic's official Claude AI desktop app

# --- Productivity and notes ---
cask "obsidian"  # Knowledge base that works on top of a local folder of plain text Markdown files
cask "zotero"  # Collect, organise, cite, and share research sources
cask "numi"  # Calculator and converter application
cask "pronotes"  # Apple Notes extension
cask "reminders-menubar"  # Simple menu bar app to view and interact with reminders
cask "thaw"  # Menu bar manager
cask "only-switch"  # System and utility switches
cask "squirrel-app"  # Rime input method engine
cask "raycast"  # Control your tools with a few keystrokes
cask "notion"  # App to write, plan, collaborate, and get organised
cask "muse"  # AI assistant for managing tasks, projects, and long-term goals
cask "open-design"  # Local-first, agent-native design tool
cask "keka"  # File archiver
cask "mos"  # Smooths scrolling and set mouse scroll directions independently
cask "libreoffice"  # Free cross-platform office suite, fresh version
cask "folx"  # Download manager with a torrent client

# --- Communication and media ---
cask "discord"  # Voice and text chat software
cask "obs"  # Open-source software for live streaming and screen recording
cask "kap"  # Open-source screen recorder built with web technology
cask "veracrypt"  # Disk encryption software focusing on security based on TrueCrypt
cask "telegram"  # Messaging app with a focus on speed and security
cask "wechat"  # Free messaging and calling application
cask "whatsapp"  # Native desktop client for WhatsApp
cask "iina"  # Free and open-source media player

# --- Fonts: Maple Mono NF (terminals) and NF CN (Zed editor, CJK in kitty) ---
cask "font-maple-mono-nf-cn"
cask "font-maple-mono-nf"

# --- Mac App Store (needs an App Store sign-in; ids from `mas list`) ---
mas "Xcode", id: 497799835
mas "Xnip", id: 1221250572
mas "Numbers", id: 409203825
mas "Pages", id: 409201541
mas "Microsoft Outlook", id: 985367838
mas "Microsoft OneNote", id: 784801555
mas "Pixea", id: 1507782672

# --- Global npm CLIs ---
npm "@anthropic-ai/claude-code"
npm "@earendil-works/pi-coding-agent"
npm "ccstatusline"
npm "neon"
npm "pyright"
