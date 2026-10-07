<h1 align="center">dotfiles</h1>

<p align="center">
  My whole Mac, as code: the terminal and editors I live in, the apps I install,<br>
  and the steps to rebuild it all on a new machine. Catppuccin Mocha on frosted glass,<br>
  built around running many Claude Code agents side by side.
</p>

<p align="center">
  <a href="https://github.com/jma49/dotfiles/actions/workflows/lint.yml"><img src="https://github.com/jma49/dotfiles/actions/workflows/lint.yml/badge.svg" alt="lint"></a>
  <img src="https://img.shields.io/badge/macOS-Apple_Silicon-cdd6f4?style=flat&logo=apple&logoColor=cdd6f4&labelColor=11111b" alt="macOS">
  <img src="https://img.shields.io/badge/Catppuccin-Mocha-cba6f7?style=flat&labelColor=11111b" alt="Catppuccin Mocha">
  <img src="https://img.shields.io/badge/managed_with-GNU_Stow-89b4fa?style=flat&labelColor=11111b" alt="GNU Stow">
  <img src="https://img.shields.io/badge/license-MIT-a6e3a1?style=flat&labelColor=11111b" alt="MIT">
</p>

<p align="center">
  <img src=".github/screenshots/terminal.png" alt="kitty with herdr: Claude Code beside Neovim, the custom tab bar on top" width="100%">
</p>

> [!IMPORTANT]
> This is more than terminal dotfiles. It is the setup I bring to every new Mac: shell and editor
> configs, the full app list in the [`Brewfile`](Brewfile) (CLI tools, apps, fonts, Mac App Store
> apps, global npm CLIs), and a checklist for the few things that can't live in a public repo.
> Clone it, run one script, and the machine feels like mine. Feel free to borrow anything.

## Highlights

- **A new Mac in one command.** `install.sh` installs Homebrew and everything I use, links every config, and sets up the agent tooling; a short checklist covers keys and sign-ins.
- **Built for parallel agents.** kitty hosts [herdr](https://herdr.dev), which keeps Claude Code sessions alive when kitty restarts; kitty's tab bar shows how many need you, are running or have finished, and plays a sound when one needs attention in a pane you aren't watching.
- **One look everywhere.** kitty, herdr, Zed, Neovim, starship, delta, bat, lsd, yazi and fzf share Catppuccin Mocha and the same glass, with dim text lifted so it stays readable over any wallpaper.
- **A theme with receipts.** Zed's *Catppuccin Blur 2.0* is generated from the official palette, with every text color checked for contrast against the glass over both a dark and a bright wallpaper.
- **Checked on every push.** CI lints shell, zsh, Lua, TOML and Python, scans the full history for secrets, verifies the generated theme and stows every package into an empty home.

## Contents

- [Gallery](#gallery)
- [New Mac](#new-mac)
- [Toolbox](#toolbox)
- [What's inside](#whats-inside)
- [Look](#look)
- [Keys](#keys)
- [Claude Code integration](#claude-code-integration)
- [Checks](#checks)
- [Credits](#credits)

## Gallery

| Zed | Neovim |
| :---: | :---: |
| <img src=".github/screenshots/zed.png" alt="Zed with Catppuccin Blur 2.0, the project panel and a Claude Code thread"> | <img src=".github/screenshots/nvim.png" alt="Neovim (AstroNvim) with lazy.nvim open on the glass"> |

## New Mac

> [!NOTE]
> Written for Apple Silicon Macs (Homebrew in `/opt/homebrew`). Sign in to the App Store first so
> the `mas` entries in the Brewfile can install.

```bash
git clone https://github.com/jma49/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

`install.sh` starts with a preflight: it stops early unless this is an Apple Silicon Mac with the
Xcode Command Line Tools and a network connection, then reports which steps are already done.
It only does what is missing, so reruns are cheap and change nothing that is in place:

1. installs Homebrew if needed, then whatever the [`Brewfile`](Brewfile) lists that isn't installed: CLI tools, apps, fonts, Mac App Store apps and global npm CLIs (it never upgrades, and skips apps already in `/Applications`),
2. installs uv and herdr with their own installers, then `latex2text` with uv for Neovim's Markdown rendering,
3. moves any existing dotfile it would replace into `~/.dotfiles-backup/<timestamp>/`,
4. links every package that isn't linked yet into `$HOME` with GNU Stow,
5. installs the Claude Code plugin described [below](#claude-code-integration) and herdr's Claude Code integration.

Run `./install.sh --check` to see that report without changing anything.

Each top-level directory is a Stow package mirroring `$HOME`, so `kitty/.config/kitty/kitty.conf`
becomes `~/.config/kitty/kitty.conf`. Edit files in the repo; the links pick changes up.

### After the script

Some things don't belong in a public repo, or need a human at the keyboard:

- [ ] **SSH keys**: copy `~/.ssh` from the old Mac, or create a key and add it to GitHub
- [ ] **GitHub CLI**: `gh auth login`
- [ ] **Secrets**: copy `~/.local_secrets` (API keys and work settings; `.zshrc` sources it, git never sees it)
- [ ] **Claude Code**: run `claude` and sign in; copy `~/.claude` if you want settings and memory back
- [ ] **Permissions**: Screen Recording for Xnip; Accessibility for Raycast and Mos
- [ ] **Shortcuts**: turn off macOS's own screenshot shortcuts (Xnip takes over) and give `cmd+space` to Raycast
- [ ] **First launches**: open Neovim once (plugins, parsers and LSPs install), and Zed (extensions install)
- [ ] **Java** (if needed): install SDKMAN, then `sdk install java`
- [ ] **App data**: import Raycast settings, reopen Obsidian vaults

## Toolbox

The tools I install first on any Mac, and why. `install.sh` installs all of them: the [`Brewfile`](Brewfile), plus herdr and uv through their own installers.

### 🖥️ Terminal and agents

<table>
<tr><td><a href="https://sw.kovidgoyal.net/kitty/"><img src="https://img.shields.io/badge/kitty-cba6f7?style=for-the-badge" alt="kitty"></a></td><td>GPU-fast terminal whose tab bar is a Python file and whose panes take remote commands. The base of everything here.</td></tr>
<tr><td><a href="https://herdr.dev"><img src="https://img.shields.io/badge/herdr-b4befe?style=for-the-badge" alt="herdr"></a></td><td>tmux for coding agents: persistent workspaces, an agent panel that knows who is working or waiting, popups.</td></tr>
<tr><td><a href="https://claude.com/claude-code"><img src="https://img.shields.io/badge/Claude_Code-fab387?style=for-the-badge&logo=claude&logoColor=11111b" alt="Claude Code"></a></td><td>The agent the whole setup is built around; a dozen sessions run side by side in herdr.</td></tr>
<tr><td><a href="https://starship.rs"><img src="https://img.shields.io/badge/starship-f5c2e7?style=for-the-badge&logo=starship&logoColor=11111b" alt="starship"></a></td><td>Fast, configurable prompt. Here: a Tide-style path and git segment in Mocha.</td></tr>
</table>

### ✍️ Editors

<table>
<tr><td><a href="https://zed.dev"><img src="https://img.shields.io/badge/Zed-89b4fa?style=for-the-badge&logo=zedindustries&logoColor=11111b" alt="Zed"></a></td><td>Native, very fast editor with first-class agent threads; the main place I read and review code.</td></tr>
<tr><td><a href="https://neovim.io"><img src="https://img.shields.io/badge/Neovim-a6e3a1?style=for-the-badge&logo=neovim&logoColor=11111b" alt="Neovim"></a></td><td>AstroNvim on top, for quick edits in the terminal and anything over SSH.</td></tr>
</table>

### ⚡ Command-line essentials

<table>
<tr><td><a href="https://github.com/BurntSushi/ripgrep"><img src="https://img.shields.io/badge/ripgrep-f38ba8?style=for-the-badge" alt="ripgrep"></a></td><td>grep, but instant and .gitignore-aware. Powers search in Neovim and in agents.</td></tr>
<tr><td><a href="https://github.com/sharkdp/fd"><img src="https://img.shields.io/badge/fd-fab387?style=for-the-badge" alt="fd"></a></td><td>find with sane defaults; feeds fzf.</td></tr>
<tr><td><a href="https://github.com/junegunn/fzf"><img src="https://img.shields.io/badge/fzf-f9e2af?style=for-the-badge" alt="fzf"></a></td><td>Fuzzy-find anything: files (ctrl+t), history (ctrl+r), directories (alt+c), projects (alt+j).</td></tr>
<tr><td><a href="https://github.com/ajeetdsouza/zoxide"><img src="https://img.shields.io/badge/zoxide-a6e3a1?style=for-the-badge" alt="zoxide"></a></td><td>cd that learns: z dot jumps to ~/dotfiles from anywhere.</td></tr>
<tr><td><a href="https://github.com/sharkdp/bat"><img src="https://img.shields.io/badge/bat-94e2d5?style=for-the-badge" alt="bat"></a></td><td>cat with syntax highlighting; also the fzf preview and the delta theme.</td></tr>
<tr><td><a href="https://github.com/lsd-rs/lsd"><img src="https://img.shields.io/badge/lsd-89dceb?style=for-the-badge" alt="lsd"></a></td><td>ls with icons and colors; aliased to ls, ll, la, lt.</td></tr>
<tr><td><a href="https://github.com/dandavison/delta"><img src="https://img.shields.io/badge/delta-74c7ec?style=for-the-badge" alt="delta"></a></td><td>Side-by-side, syntax-highlighted git diffs.</td></tr>
<tr><td><a href="https://github.com/jesseduffield/lazygit"><img src="https://img.shields.io/badge/lazygit-89b4fa?style=for-the-badge" alt="lazygit"></a></td><td>The fastest way to stage hunks and rewrite commits; one key away in a herdr popup.</td></tr>
<tr><td><a href="https://yazi-rs.github.io"><img src="https://img.shields.io/badge/yazi-b4befe?style=for-the-badge" alt="yazi"></a></td><td>Terminal file manager with image and Markdown previews; y opens it and cds on exit.</td></tr>
<tr><td><a href="https://github.com/aristocratos/btop"><img src="https://img.shields.io/badge/btop-cba6f7?style=for-the-badge" alt="btop"></a></td><td>Beautiful resource monitor.</td></tr>
<tr><td><a href="https://cli.github.com"><img src="https://img.shields.io/badge/gh-f5c2e7?style=for-the-badge&logo=github&logoColor=11111b" alt="gh"></a></td><td>PRs, CI runs and releases without leaving the terminal.</td></tr>
<tr><td><a href="https://docs.astral.sh/uv/"><img src="https://img.shields.io/badge/uv-f5e0dc?style=for-the-badge" alt="uv"></a></td><td>Python packages and tools, ten to a hundred times faster than pip.</td></tr>
</table>

### 🍎 Mac apps

<table>
<tr><td><a href="https://raycast.com"><img src="https://img.shields.io/badge/Raycast-f38ba8?style=for-the-badge&logo=raycast&logoColor=11111b" alt="Raycast"></a></td><td>Spotlight replacement: launcher, clipboard history, window snapping, snippets.</td></tr>
<tr><td><a href="https://orbstack.dev"><img src="https://img.shields.io/badge/OrbStack-fab387?style=for-the-badge" alt="OrbStack"></a></td><td>Docker and Linux VMs that start in seconds and barely touch the battery.</td></tr>
<tr><td><a href="https://xnipapp.com"><img src="https://img.shields.io/badge/Xnip-f9e2af?style=for-the-badge" alt="Xnip"></a></td><td>Screenshots with scrolling capture, annotation and pinning.</td></tr>
<tr><td><a href="https://obsidian.md"><img src="https://img.shields.io/badge/Obsidian-cba6f7?style=for-the-badge&logo=obsidian&logoColor=11111b" alt="Obsidian"></a></td><td>Notes as plain Markdown files in a folder.</td></tr>
<tr><td><a href="https://mos.caldis.me"><img src="https://img.shields.io/badge/Mos-a6e3a1?style=for-the-badge" alt="Mos"></a></td><td>Smooth scrolling for a regular mouse, with its own scroll direction.</td></tr>
<tr><td><a href="https://github.com/thaw-app/Thaw"><img src="https://img.shields.io/badge/Thaw-89dceb?style=for-the-badge" alt="Thaw"></a></td><td>Hides and tidies menu bar icons.</td></tr>
<tr><td><a href="https://iina.io"><img src="https://img.shields.io/badge/IINA-b4befe?style=for-the-badge" alt="IINA"></a></td><td>The media player macOS should ship with.</td></tr>
<tr><td><a href="https://www.keka.io"><img src="https://img.shields.io/badge/Keka-94e2d5?style=for-the-badge" alt="Keka"></a></td><td>Archives of every format, with drag and drop.</td></tr>
</table>

## What's inside

| Package | What it sets up |
| --- | --- |
| [`kitty`](kitty/.config/kitty) | Terminal: Maple Mono NF, glass over Mocha crust (0.88, blur 64), craftzdog-style tab bar with agent status ([`tab_bar.py`](kitty/.config/kitty/tab_bar.py)) |
| [`herdr`](herdr/.config/herdr) | Agent workspace inside kitty: Mocha borders, lavender focus, glass panels, lazygit popup |
| [`zsh`](zsh) | antidote plugins, vi mode with cursor shapes, fzf with previews, zoxide, project jumper |
| [`starship`](starship/.config/starship.toml) | Prompt: dim parent directories, bold repo root, one blue git segment |
| [`zed`](zed/.config/zed) | Settings, keymap and the generated Catppuccin Blur 2.0 themes |
| [`nvim`](nvim/.config/nvim) | AstroNvim v6 on Catppuccin Mocha, tuned for a transparent background |
| [`git`](git) | delta pager (side by side, Catppuccin Mocha), global ignores |
| [`bat`](bat/.config/bat) · [`lsd`](lsd/.config/lsd) · [`yazi`](yazi/.config/yazi) | Catppuccin Mocha for the pager, `ls` and the file manager |
| [`claude`](claude/.claude/dotfiles-plugins) | Claude Code plugin that reports each session's state to the tab bar |

## Look

<p>
  <img src="https://img.shields.io/badge/crust-11111b-11111b?style=flat-square" alt="crust">
  <img src="https://img.shields.io/badge/base-1e1e2e-1e1e2e?style=flat-square" alt="base">
  <img src="https://img.shields.io/badge/surface1-45475a-45475a?style=flat-square" alt="surface1">
  <img src="https://img.shields.io/badge/overlay2-9399b2-9399b2?style=flat-square" alt="overlay2">
  <img src="https://img.shields.io/badge/text-cdd6f4-cdd6f4?style=flat-square" alt="text">
  <img src="https://img.shields.io/badge/lavender-b4befe-b4befe?style=flat-square" alt="lavender">
  <img src="https://img.shields.io/badge/blue-89b4fa-89b4fa?style=flat-square" alt="blue">
  <img src="https://img.shields.io/badge/yellow-f9e2af-f9e2af?style=flat-square" alt="yellow">
  <img src="https://img.shields.io/badge/rosewater-f5e0dc-f5e0dc?style=flat-square" alt="rosewater">
</p>

Catppuccin is designed for opaque backgrounds, so a few colors move for glass:

- **The tint is crust, not base.** A darker tint keeps the frost from turning milky and text crisp (craftzdog's Solarized Osaka uses the same trick).
- **Dim text is lifted.** Secondary text in Neovim (file stats, git blame, inlay hints) moves from `surface`/`overlay0` to `overlay2`; Zed adjusts lightness only, never hue.
- **Selection is solid.** An opaque, mid-tone lavender-hue color, solved per flavor to stand out from the glass with text on it at 4.5:1 or better.
- **Accents are shared.** Lavender marks focus (kitty, herdr, Zed borders); the orange cursor matches across kitty and Zed.

**Zed: Catppuccin Blur 2.0.** Six flavors (Latte, Iced Latte, Frappé, Macchiato, Mocha, Espresso),
generated by [`zed/build-catppuccin-blur-2.py`](zed/build-catppuccin-blur-2.py) from catppuccin/zed
at a pinned commit. Edit the script rather than the JSON; bump `OFFICIAL_REF` to follow upstream.

## Keys

<details>
<summary><b>kitty</b></summary>

| Keys | Action |
| --- | --- |
| `cmd+t` / `cmd+w` | New / close tab |
| `cmd+1..9`, `cmd+shift+[` / `]` | Go to tab / previous / next |
| `cmd+d` / `cmd+shift+d` | Split right / down |
| `cmd+shift+h/j/k/l` | Focus pane left / down / up / right |
| `cmd+alt+h/j/k/l` | Resize pane |
| `cmd+shift+m` | Maximize pane |
| `cmd+alt+w` | Close pane |
| `cmd+alt+g` | Toggle grid layout, to watch several agents |
| `cmd+alt+m` | Move pane to another tab |
| `cmd+shift+a` | Open a Claude agent view on the right |
| `cmd+s` · `cmd+p` · `cmd+shift+f` · `cmd+b` | Neovim save · find files · grep · file tree (only while nvim runs) |

Left Option works as Alt; right Option still types special characters.

</details>

<details>
<summary><b>herdr</b> (prefix <code>ctrl+b</code>)</summary>

| Keys | Action |
| --- | --- |
| `prefix y` | lazygit in a popup, in the focused pane's directory |
| `prefix q` | Detach this client; sessions keep running |
| `prefix ?` | Every herdr binding |

</details>

<details>
<summary><b>zsh</b> (vi mode)</summary>

| Keys | Action |
| --- | --- |
| `esc` | Normal mode (block cursor); insert mode shows a beam |
| `alt+j` | Jump to a project in `~/Code`, `~/Code/personal`, `~/.config` or `~/dotfiles` |
| `ctrl+t` / `alt+c` | Pick a file (bat preview) / a directory (tree preview) with fzf |
| `ctrl+r` | Search history with fzf |
| `y` | yazi, landing in the directory you leave it in |

</details>

<details>
<summary><b>Zed</b></summary>

| Keys | Action |
| --- | --- |
| `alt+]` / `alt+[` | Next / previous diff hunk |
| `cmd+alt+d` | Project-wide diff |
| `cmd+shift+a` | Agent panel |
| `cmd+1..9` | Go to editor tab |

</details>

## Claude Code integration

```mermaid
flowchart LR
  A[Claude Code hooks] -->|state| B[agent-state.sh]
  B --> C[(~/.cache/claude-agents/*.json)]
  C --> D[kitty tab_bar.py]
  E[herdr] -->|focused pane| D
  D --> F[Tab bar counts<br>and alert sounds]
```

The `agent-status` plugin's hooks record each session as needing you, running, done or failed. The kitty tab
bar reads those files every second, shows the counts and plays a sound when a session needs you in a pane you
aren't looking at. Sessions inside herdr have no kitty window of their own, so the tab bar asks herdr which
pane is focused.

`~/.claude/settings.json` is not managed here: Claude Code rewrites it (plugins, permissions), which would
replace a Stow link with a plain file. `install.sh` installs the plugin when `claude` is available; otherwise:

```bash
claude plugin marketplace add ~/.claude/dotfiles-plugins
claude plugin install agent-status@dotfiles
```

Restart running sessions (or run `/reload-plugins`) to pick it up, and restart kitty after changing `tab_bar.py`.

## Checks

[`lint.yml`](.github/workflows/lint.yml) runs on every push and pull request:

| Check | Tool |
| --- | --- |
| Secrets across the full history | gitleaks, with a [Tavily rule](.gitleaks.toml) added |
| Shell scripts | shellcheck |
| zsh syntax | `zsh -n` |
| Lua formatting | stylua |
| TOML formatting | taplo |
| Python syntax | `py_compile` |
| Zed theme matches its generator | `build-catppuccin-blur-2.py --check` |
| Every package stows into an empty home | GNU Stow |

The same tools come from the `Brewfile`, so they run locally too; run `gitleaks git` before pushing.

## Credits

- [Catppuccin](https://github.com/catppuccin) for the palette and the official themes everything starts from
- [craftzdog/dotfiles](https://github.com/craftzdog/dotfiles) for the darker glass, the Tide-style prompt and the status-line tab bar
- [jenslys/zed-catppuccin-blur](https://github.com/jenslys/zed-catppuccin-blur) for the Zed glass layout and the Iced Latte and Espresso flavors
- [AstroNvim](https://github.com/AstroNvim/AstroNvim) for the Neovim base

## License

[MIT](LICENSE). Catppuccin-derived themes keep their upstream MIT licenses.
