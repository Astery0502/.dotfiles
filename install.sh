#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"
BACKUP_DIR="$HOME/.dotfiles-backup/$(date +%Y%m%d_%H%M%S)"
BACKED_UP=0

# Symlink map: source (relative to DOTFILES_DIR) -> target (absolute)
declare -a LINKS=(
    "bash/.bashrc:$HOME/.bashrc"
    "bash/.bash_profile:$HOME/.bash_profile"
    "bash/.bash_aliases:$HOME/.bash_aliases"
    "vim/.vimrc:$HOME/.vimrc"
    "git/.gitconfig:$HOME/.gitconfig"
    "claude/CLAUDE.md:$HOME/.claude/CLAUDE.md"
    "claude/settings.json:$HOME/.claude/settings.json"
    "claude/skills/planning-orchestration:$HOME/.claude/skills/planning-orchestration"
    "claude/skills/planning-with-files:$HOME/.claude/skills/planning-with-files"
    "tmux/.tmux.conf:$HOME/.tmux.conf"
)

backup_file() {
    local target="$1"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
        if [ $BACKED_UP -eq 0 ]; then
            mkdir -p "$BACKUP_DIR"
            BACKED_UP=1
        fi
        local relpath="${target#$HOME/}"
        local backup_path="$BACKUP_DIR/$relpath"
        mkdir -p "$(dirname "$backup_path")"
        cp -a "$target" "$backup_path"
        echo "  backed up: $target -> $backup_path"
    fi
}

create_symlink() {
    local src="$1"
    local target="$2"

    # Create parent directory if needed
    mkdir -p "$(dirname "$target")"

    # Back up existing real file (not symlink)
    backup_file "$target"

    # Remove existing file, symlink, or directory
    if [ -e "$target" ] || [ -L "$target" ]; then
        if [ -d "$target" ] && [ ! -L "$target" ]; then
            rm -rf "$target"
        else
            rm "$target"
        fi
    fi

    ln -s "$src" "$target"
    echo "  linked: $target -> $src"
}

echo "=== dotfiles install ==="
echo "Source: $DOTFILES_DIR"
echo ""

echo "Creating symlinks..."
for entry in "${LINKS[@]}"; do
    src_rel="${entry%%:*}"
    target="${entry##*:}"
    src_abs="$DOTFILES_DIR/$src_rel"

    if [ ! -e "$src_abs" ]; then
        echo "  SKIP (missing): $src_abs"
        continue
    fi

    create_symlink "$src_abs" "$target"
done

echo ""
if [ $BACKED_UP -eq 1 ]; then
    echo "Backups saved to: $BACKUP_DIR"
else
    echo "No backups needed (no existing real files were replaced)."
fi

echo ""
echo "Installing Claude Code plugins..."
# Add more plugins here as needed
declare -a PLUGINS=(
    "superpowers@claude-plugins-official"
)

if command -v claude &>/dev/null; then
    installed_plugins="$(claude plugins list 2>/dev/null)"
    for plugin in "${PLUGINS[@]}"; do
        plugin_name="${plugin%%@*}"
        if echo "$installed_plugins" | grep -q "$plugin_name"; then
            echo "  already installed: $plugin"
        else
            echo "  installing: $plugin"
            claude plugins install "$plugin"
        fi
    done
else
    echo "  SKIP: 'claude' CLI not found, skipping plugin install"
fi

echo ""
echo "Done. Local override files to create manually:"
echo "  ~/.bashrc.local          (see local/.bashrc.local.example)"
echo "  ~/.vimrc.local           (see local/.vimrc.local.example)"
echo "  ~/.gitconfig.local       (for machine-specific git config)"
echo "  ~/.claude/settings.local.json (see claude/settings.local.example.json)"
