# Dotfiles Repository — Claude Code Instructions

This is a personal dotfiles repository. It stores shared shell/editor/tool configuration and uses symlinks to expose them to `$HOME`.

## Repository Structure

```
bash/          → .bashrc, .bash_profile, .bash_aliases (shared versions)
vim/           → .vimrc (shared version)
git/           → .gitconfig (shared, includes local override via [include])
claude/        → settings.json (shared Claude Code settings)
tmux/          → .tmux.conf (shared)
local/         → *.example templates for machine-specific overrides
install.sh     → Creates symlinks and backs up existing files
```

## Setup Workflow

When the user asks to "set up dotfiles" or "install dotfiles", follow these steps:

### Step 1: Run install.sh
```bash
cd ~/.dotfiles && ./install.sh
```
This creates symlinks from `$HOME` into this repo and backs up any existing real files to `~/.dotfiles-backup/<timestamp>/`.

### Step 2: Create local override files
Guide the user to create these files based on the examples:

1. **~/.bashrc.local** — from `local/.bashrc.local.example`
   - Ask which conda path to use (if any)
   - Ask about project-specific PATH entries
   - Ask if they have a secrets env file to source
   - **Add `ANTHROPIC_API_KEY`** — required to skip browser login when running `claude`

2. **~/.vimrc.local** — from `local/.vimrc.local.example`
   - Ask about local color scheme or font preferences

3. **~/.gitconfig.local** — for machine-specific git settings
   - Ask if they need a different user.email for this machine
   - Ask about signing keys or credential helpers

4. **~/.claude/settings.local.json** — from `claude/settings.local.example.json`
   - Ask about additional permissions needed on this machine

### Step 3: Verify
After setup, verify symlinks are working:
```bash
ls -la ~/.bashrc ~/.vimrc ~/.gitconfig ~/.claude/settings.json ~/.tmux.conf
```

## Rules

- NEVER commit secrets, API keys, tokens, or private credentials
- NEVER modify `*.local` files through git — they are machine-specific and git-ignored
- Machine-specific paths (conda, project dirs) belong in `~/.bashrc.local`
- When adding a new config file: place shared version in a category dir, add symlink entry to `install.sh`, create a `local/*.example` if it needs local overrides
- `install.sh` is idempotent — safe to re-run at any time

## Symlink Map

| Repo File | Home Target |
|---|---|
| `bash/.bashrc` | `~/.bashrc` |
| `bash/.bash_profile` | `~/.bash_profile` |
| `bash/.bash_aliases` | `~/.bash_aliases` |
| `vim/.vimrc` | `~/.vimrc` |
| `git/.gitconfig` | `~/.gitconfig` |
| `claude/settings.json` | `~/.claude/settings.json` |
| `claude/skills/planning-orchestration` | `~/.claude/skills/planning-orchestration` |
| `claude/skills/planning-with-files` | `~/.claude/skills/planning-with-files` |
| `tmux/.tmux.conf` | `~/.tmux.conf` |

## Claude Code Plugins

`install.sh` also installs Claude Code plugins via `claude plugins install`. The list lives in the `PLUGINS` array in `install.sh`. To add a new plugin, append its identifier (e.g. `myplugin@claude-plugins-official`) to that array.

Currently managed:
- `superpowers@claude-plugins-official`

## Adding New Configs

To add a new tool's config (e.g., `starship.toml`):
1. Create directory: `starship/`
2. Place shared config: `starship/starship.toml`
3. Add to `LINKS` array in `install.sh`: `"starship/starship.toml:$HOME/.config/starship.toml"`
4. If local overrides needed: create `local/starship.toml.local.example`
