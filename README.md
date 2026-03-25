# dotfiles

Personal configuration files managed with git and symlinks.

## Quick Start

```bash
git clone <repo-url> ~/.dotfiles
cd ~/.dotfiles
./install.sh
```

Then create local override files as needed (see examples in `local/`).

## Structure

```
~/.dotfiles/
├── bash/          # Bash config (.bashrc, .bash_profile, .bash_aliases)
├── vim/           # Vim config (.vimrc)
├── git/           # Git config (.gitconfig)
├── claude/        # Claude Code settings
├── tmux/          # Tmux config
├── local/         # Example templates for machine-specific overrides
├── install.sh     # Symlink installer (backs up existing files)
└── CLAUDE.md      # Instructions for LLM-assisted setup
```

## How It Works

- Shared config files live in this repo under category directories
- `install.sh` creates symlinks from `$HOME` pointing into this repo
- Machine-specific values go in `*.local` files which are git-ignored
- Main configs source their `*.local` counterparts if they exist

## Local Override Files

These are **not tracked** by git. Create them from the examples:

| Example Template | Create As |
|---|---|
| `local/.bashrc.local.example` | `~/.bashrc.local` |
| `local/.vimrc.local.example` | `~/.vimrc.local` |
| `claude/settings.local.example.json` | `~/.claude/settings.local.json` |

## Adding a New Config

1. Place the shared version in the appropriate directory (e.g., `tool/.toolrc`)
2. Add a symlink entry in `install.sh`
3. If it needs machine-specific overrides, add a `local/.toolrc.local.example`
4. Make the main config source the local file conditionally

## LLM-Assisted Setup

Open Claude Code in this directory and say "set up my dotfiles". Claude will read `CLAUDE.md` and walk you through the full setup including local file creation.

## Rules

- Never commit secrets, API keys, tokens, or private endpoints
- Machine-specific paths belong in `*.local` files
- `install.sh` is idempotent — safe to re-run
