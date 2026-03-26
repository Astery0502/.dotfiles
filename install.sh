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

if ! command -v uv &>/dev/null; then
    echo "Installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    echo "  uv installed"
else
    echo "uv already installed: $(uv --version)"
fi

if ! command -v gh &>/dev/null; then
    echo "Installing gh (GitHub CLI)..."
    if command -v brew &>/dev/null; then
        brew install gh
    else
        # Universal binary install — no sudo, no package manager required
        _gh_os="$(uname -s | tr '[:upper:]' '[:lower:]')"
        _gh_arch="$(uname -m)"
        case "$_gh_arch" in
            x86_64)  _gh_arch="amd64" ;;
            aarch64|arm64) _gh_arch="arm64" ;;
            *) echo "  WARNING: unsupported arch $_gh_arch, skipping gh install"; _gh_arch="" ;;
        esac
        if [ -n "$_gh_arch" ]; then
            _gh_ver="$(curl -fsSL https://api.github.com/repos/cli/cli/releases/latest | grep '"tag_name"' | sed 's/.*"v\([^"]*\)".*/\1/')"
            _gh_url="https://github.com/cli/cli/releases/download/v${_gh_ver}/gh_${_gh_ver}_${_gh_os}_${_gh_arch}.tar.gz"
            mkdir -p "$HOME/.local/bin"
            curl -fsSL "$_gh_url" | tar -xz -C /tmp
            mv "/tmp/gh_${_gh_ver}_${_gh_os}_${_gh_arch}/bin/gh" "$HOME/.local/bin/gh"
            echo "  gh ${_gh_ver} installed to ~/.local/bin/gh"
            if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
                echo 'export PATH="$PATH:$HOME/.local/bin"' >> "$HOME/.bashrc.local"
                echo "  Added ~/.local/bin to PATH in ~/.bashrc.local"
            fi
        fi
    fi
else
    echo "gh already installed: $(gh --version | head -1)"
fi
if ! gh auth status &>/dev/null; then
    echo "  NOTE: run 'gh auth login' to authenticate with GitHub"
fi

if ! command -v claude &>/dev/null; then
    echo "WARNING: 'claude' CLI not found."
    echo "  Install it with:"
    echo "    curl -fsSL https://claude.ai/install.sh | bash"
    echo "  Then re-run this script."
    exit 1
fi

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
echo "Installing Claude Code skills..."
SKILLS_LIST="$DOTFILES_DIR/claude/skills.list"
if [ -f "$SKILLS_LIST" ]; then
    while IFS= read -r line || [ -n "$line" ]; do
        # Skip blank lines and comments
        [[ "$line" =~ ^[[:space:]]*$ || "$line" =~ ^[[:space:]]*# ]] && continue

        skill_name="${line%% *}"
        skill_url="${line#* }"
        [ "$skill_url" = "$skill_name" ] && skill_url=""  # no URL = local skill

        if [[ "$skill_name" == plugin:* ]]; then
            # Handled in plugin install phase below
            continue
        elif [ -n "$skill_url" ]; then
            # Remote skill: git-clone directly to ~/.claude/skills/
            skill_target="$HOME/.claude/skills/$skill_name"
            mkdir -p "$HOME/.claude/skills"
            if [ -d "$skill_target/.git" ]; then
                echo "  updating: $skill_name"
                git -C "$skill_target" pull --ff-only -q
            elif [ -e "$skill_target" ]; then
                echo "  already present (non-git): $skill_name"
            else
                echo "  cloning: $skill_name from $skill_url"
                git clone --depth 1 -q "$skill_url" "$skill_target"
            fi
        else
            # Local skill: symlink from claude/skills/ into ~/.claude/skills/
            skill_src="$DOTFILES_DIR/claude/skills/$skill_name"
            skill_target="$HOME/.claude/skills/$skill_name"
            if [ ! -e "$skill_src" ]; then
                echo "  SKIP (missing local skill): $skill_name"
                continue
            fi
            create_symlink "$skill_src" "$skill_target"
        fi
    done < "$SKILLS_LIST"
else
    echo "  SKIP: claude/skills.list not found"
fi

echo ""
echo "Installing Claude Code plugins..."
if [ -f "$SKILLS_LIST" ]; then
    installed_plugins="$(claude plugins list 2>/dev/null)"
    while IFS= read -r line || [ -n "$line" ]; do
        [[ "$line" =~ ^[[:space:]]*$ || "$line" =~ ^[[:space:]]*# ]] && continue
        [[ "${line%% *}" != plugin:* ]] && continue

        plugin="${line#plugin:}"
        plugin_name="${plugin%%@*}"
        if echo "$installed_plugins" | grep -q "$plugin_name"; then
            echo "  already installed: $plugin"
        else
            echo "  installing: $plugin"
            claude plugins install "$plugin"
        fi
    done < "$SKILLS_LIST"
fi

echo ""
echo "Done. Local override files to create manually:"
echo "  ~/.bashrc.local          (see local/.bashrc.local.example)"
echo "  ~/.vimrc.local           (see local/.vimrc.local.example)"
echo "  ~/.gitconfig.local       (for machine-specific git config)"
echo "  ~/.claude/settings.local.json (see claude/settings.local.example.json)"
