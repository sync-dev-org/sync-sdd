#!/bin/sh
set -eu

# sync-sdd installer
# Usage:
#   curl -LsSf https://raw.githubusercontent.com/sync-dev-org/sync-sdd/main/install.sh | sh
#   curl -LsSf https://raw.githubusercontent.com/sync-dev-org/sync-sdd/main/install.sh | sh -s -- --update
#   curl -LsSf https://raw.githubusercontent.com/sync-dev-org/sync-sdd/main/install.sh | sh -s -- --version v0.3.0

REPO="sync-dev-org/sync-sdd"
DEFAULT_BRANCH="main"

# --- Colors ---
if [ -t 1 ]; then
    RED=$(printf '\033[0;31m')
    GREEN=$(printf '\033[0;32m')
    YELLOW=$(printf '\033[0;33m')
    CYAN=$(printf '\033[0;36m')
    BOLD=$(printf '\033[1m')
    RESET=$(printf '\033[0m')
else
    RED="" GREEN="" YELLOW="" CYAN="" BOLD="" RESET=""
fi

# --- Helpers ---
info()  { printf "${CYAN}info${RESET}: %s\n" "$1"; }
warn()  { printf "${YELLOW}warn${RESET}: %s\n" "$1"; }
error() { printf "${RED}error${RESET}: %s\n" "$1" >&2; }
success() { printf "${GREEN}success${RESET}: %s\n" "$1"; }

confirm() {
    printf "%s [y/N] " "$1"
    if [ -t 0 ]; then
        read -r answer
    elif [ -e /dev/tty ]; then
        read -r answer < /dev/tty
    else
        return 1  # Non-interactive: default to no
    fi
    case "$answer" in
        [yY]*) return 0 ;;
        *) return 1 ;;
    esac
}

SDD_MARKER_START="<!-- sdd:start -->"
SDD_MARKER_END="<!-- sdd:end -->"

usage() {
    cat <<EOF
${BOLD}sync-sdd installer${RESET}

Spec-Driven Development framework for Claude Code.

${BOLD}USAGE${RESET}:
    curl -LsSf <url>/install.sh | sh
    curl -LsSf <url>/install.sh | sh -s -- [OPTIONS]

${BOLD}OPTIONS${RESET}:
    --update          Update framework files only (preserves user files)
    --version <tag>   Install a specific version (default: latest)
    --force           Overwrite existing framework files without prompting
    --uninstall       Remove all SDD framework files
    --help            Show this help message

${BOLD}FRAMEWORK FILES${RESET} (managed by installer):
    .claude/commands/sdd-*.md    Skill definitions
    .claude/agents/sdd-*.md      Agent definitions
    .claude/CLAUDE.md            Framework instructions (appended between markers)
    .claude/settings.json        Default settings (prompt before overwrite)

    .claude/sdd/settings/rules/      Development rules
    .claude/sdd/settings/templates/  Spec/steering/knowledge templates

${BOLD}USER FILES${RESET} (never touched by installer):
    .claude/sdd/project/steering/    Project-specific steering
    .claude/sdd/project/specs/       Feature specifications
    .claude/sdd/project/knowledge/   Knowledge base entries
    .claude/handover.md              Session handover
    .claude/settings.local.json      Local setting overrides
EOF
    exit 0
}

# --- Parse arguments ---
UPDATE=false
FORCE=false
UNINSTALL=false
VERSION=""

while [ $# -gt 0 ]; do
    case "$1" in
        --update)    UPDATE=true ;;
        --force)     FORCE=true ;;
        --uninstall) UNINSTALL=true ;;
        --version)   shift; VERSION="${1:-}" ;;
        --help|-h)   usage ;;
        *)           error "Unknown option: $1"; usage ;;
    esac
    shift
done

# --- Uninstall ---
if [ "$UNINSTALL" = true ]; then
    info "Removing SDD framework files..."

    # Remove framework-managed files only
    rm -f .claude/commands/sdd-*.md
    rm -f .claude/agents/sdd-*.md
    rm -rf .claude/sdd/settings/rules/ \
           .claude/sdd/settings/templates/

    # Remove SDD section from CLAUDE.md (preserve user content)
    if [ -f .claude/CLAUDE.md ] && grep -q "$SDD_MARKER_START" .claude/CLAUDE.md; then
        awk -v start="$SDD_MARKER_START" -v end="$SDD_MARKER_END" \
            '$0 == start { skip=1; next } $0 == end { skip=0; next } !skip { print }' \
            .claude/CLAUDE.md > .claude/CLAUDE.md.tmp
        # Remove trailing blank lines
        sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' .claude/CLAUDE.md.tmp > .claude/CLAUDE.md
        rm -f .claude/CLAUDE.md.tmp
        # Delete file if it's now empty
        if [ ! -s .claude/CLAUDE.md ]; then
            rm -f .claude/CLAUDE.md
        else
            info "Removed SDD section from .claude/CLAUDE.md (your content preserved)"
        fi
    fi

    # Clean up empty directories
    rmdir .claude/commands .claude/agents .claude/sdd/settings .claude/sdd 2>/dev/null || true

    if [ -f .claude/settings.json ]; then
        warn ".claude/settings.json was left in place (may contain your customizations)"
    fi

    success "SDD framework files removed"
    info "User files (.claude/sdd/project/) were preserved"
    exit 0
fi

# --- Pre-flight checks ---
if [ ! -d .git ] && [ "$FORCE" = false ]; then
    error "Not a git repository. Run this from your project root."
    error "Use --force to install anyway."
    exit 1
fi

# --- Migrate from .kiro/ to .claude/sdd/ ---
if [ -d .kiro ] && [ "$UNINSTALL" = false ]; then
    info "Detected legacy .kiro/ directory"

    # Migrate user files
    for dir in steering specs knowledge; do
        if [ -d ".kiro/$dir" ]; then
            if [ -d ".claude/sdd/project/$dir" ]; then
                warn ".claude/sdd/project/$dir already exists, skipping .kiro/$dir migration"
            else
                mkdir -p .claude/sdd/project
                mv ".kiro/$dir" ".claude/sdd/project/$dir"
                info "Migrated .kiro/$dir -> .claude/sdd/project/$dir"
            fi
        fi
    done

    # Remove old framework-managed files
    rm -rf .kiro/settings/rules/ .kiro/settings/templates/
    rmdir .kiro/settings .kiro 2>/dev/null || true

    if [ -d .kiro ]; then
        warn ".kiro/ still has files; check manually"
    else
        success "Legacy .kiro/ directory fully migrated"
    fi
fi

# --- Download ---
if [ -n "$VERSION" ]; then
    ARCHIVE_URL="https://github.com/${REPO}/archive/refs/tags/${VERSION}.tar.gz"
else
    ARCHIVE_URL="https://github.com/${REPO}/archive/refs/heads/${DEFAULT_BRANCH}.tar.gz"
fi

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

info "Downloading sync-sdd..."
if ! curl -LsSf "$ARCHIVE_URL" -o "$TMPDIR/sync-sdd.tar.gz" 2>/dev/null; then
    error "Failed to download from ${ARCHIVE_URL}"
    error "Check the repository URL and version tag."
    exit 1
fi

tar xzf "$TMPDIR/sync-sdd.tar.gz" -C "$TMPDIR"
SRC=$(find "$TMPDIR" -maxdepth 1 -type d -name "sync-sdd*" | head -1)

if [ -z "$SRC" ] || [ ! -d "$SRC/framework" ]; then
    error "Downloaded archive doesn't contain expected framework/ directory"
    exit 1
fi

# --- Install framework files ---
install_file() {
    src="$1"
    dest="$2"

    if [ -f "$dest" ] && [ "$FORCE" = false ] && [ "$UPDATE" = false ]; then
        warn "Skipping existing file: $dest (use --force to overwrite)"
        return
    fi

    mkdir -p "$(dirname "$dest")"
    cp "$src" "$dest"
}

install_dir() {
    src_dir="$1"
    dest_dir="$2"

    if [ ! -d "$src_dir" ]; then
        return
    fi

    find "$src_dir" -type f | while read -r src_file; do
        rel="${src_file#"$src_dir"/}"
        install_file "$src_file" "$dest_dir/$rel"
    done
}

info "Installing framework files..."

# .claude/ framework files
install_dir "$SRC/framework/claude/commands" ".claude/commands"
install_dir "$SRC/framework/claude/agents"   ".claude/agents"

# .claude/CLAUDE.md - marker-based section management
install_claude_md() {
    src_file="$1"
    dest=".claude/CLAUDE.md"
    mkdir -p .claude

    # Build marked content block
    marked_block="$SDD_MARKER_START
$(cat "$src_file")
$SDD_MARKER_END"

    if [ ! -f "$dest" ]; then
        # No existing file - create with markers
        printf '%s\n' "$marked_block" > "$dest"
        return
    fi

    if grep -q "$SDD_MARKER_START" "$dest"; then
        # Markers exist - replace content between them
        awk -v start="$SDD_MARKER_START" -v end="$SDD_MARKER_END" \
            'BEGIN { skip=0 } $0 == start { skip=1; next } $0 == end { skip=0; next } !skip { print }' \
            "$dest" > "$dest.tmp"
        # Remove trailing blank lines then append new block
        sed -e :a -e '/^\n*$/{$d;N;ba' -e '}' "$dest.tmp" > "$dest"
        rm -f "$dest.tmp"
        printf '\n%s\n' "$marked_block" >> "$dest"
        info "Updated SDD section in .claude/CLAUDE.md"
        return
    fi

    # File exists without markers - user's own CLAUDE.md
    if [ "$FORCE" = true ]; then
        printf '\n%s\n' "$marked_block" >> "$dest"
        info "Appended SDD section to existing .claude/CLAUDE.md"
    elif [ "$UPDATE" = true ]; then
        warn ".claude/CLAUDE.md exists but has no SDD markers - skipping"
        warn "Run with --force to append SDD section"
    else
        echo ""
        warn "Existing .claude/CLAUDE.md detected"
        info "SDD instructions will be appended between markers (your content stays intact)"
        if confirm "  Append SDD section to .claude/CLAUDE.md?"; then
            printf '\n%s\n' "$marked_block" >> "$dest"
            info "Appended SDD section to .claude/CLAUDE.md"
        else
            warn "Skipped .claude/CLAUDE.md — SDD commands may not work correctly without it"
        fi
    fi
}
install_claude_md "$SRC/framework/claude/CLAUDE.md"

# .claude/settings.json - special handling
if [ -f .claude/settings.json ]; then
    if [ "$UPDATE" = true ]; then
        info "Preserving existing .claude/settings.json"
    elif [ "$FORCE" = true ]; then
        install_file "$SRC/framework/claude/settings.json" ".claude/settings.json"
    else
        echo ""
        warn "Existing .claude/settings.json detected"
        if confirm "  Overwrite with SDD defaults?"; then
            install_file "$SRC/framework/claude/settings.json" ".claude/settings.json"
        else
            info "Kept existing .claude/settings.json"
            echo ""
            info "Ensure your settings.json includes the following for agent team features:"
            echo "  {\"env\": {\"CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS\": \"1\"}}"
        fi
    fi
else
    install_file "$SRC/framework/claude/settings.json" ".claude/settings.json"
fi

# .claude/sdd/settings/ framework files
install_dir "$SRC/framework/claude/sdd/settings/rules"     ".claude/sdd/settings/rules"
install_dir "$SRC/framework/claude/sdd/settings/templates"  ".claude/sdd/settings/templates"

# --- Remove stale framework files on update ---
if [ "$UPDATE" = true ] || [ "$FORCE" = true ]; then
    remove_stale() {
        local_dir="$1"
        src_dir="$2"
        pattern="$3"

        if [ ! -d "$local_dir" ]; then
            return
        fi

        find "$local_dir" -name "$pattern" -type f | while read -r local_file; do
            rel="${local_file#"$local_dir"/}"
            if [ ! -f "$src_dir/$rel" ]; then
                rm "$local_file"
                warn "Removed stale file: $local_file"
            fi
        done
    }

    remove_stale ".claude/commands" "$SRC/framework/claude/commands" "sdd-*.md"
    remove_stale ".claude/agents"   "$SRC/framework/claude/agents"   "sdd-*.md"
    remove_stale ".claude/sdd/settings/rules"     "$SRC/framework/claude/sdd/settings/rules"     "*.md"
    remove_stale ".claude/sdd/settings/templates" "$SRC/framework/claude/sdd/settings/templates"  "*"

    # Clean up empty directories left after stale file removal
    find .claude/sdd/settings/templates -depth -type d -empty -delete 2>/dev/null || true
fi

# --- Summary ---
echo ""
if [ "$UPDATE" = true ]; then
    success "SDD framework updated!"
else
    success "SDD framework installed!"
fi

echo ""
printf "${BOLD}Installed:${RESET}\n"
echo "  .claude/commands/    $(find .claude/commands -name 'sdd-*.md' 2>/dev/null | wc -l | tr -d ' ') skills"
echo "  .claude/agents/      $(find .claude/agents -name 'sdd-*.md' 2>/dev/null | wc -l | tr -d ' ') agents"
echo "  .claude/CLAUDE.md    Framework instructions (marker-managed)"
echo "  .claude/sdd/         Rules + templates"

if [ "$UPDATE" = false ]; then
    echo ""
    printf "${BOLD}Quick start:${RESET}\n"
    echo "  1. cd your-project"
    echo "  2. claude                        # Start Claude Code"
    echo "  3. /sdd-steering                 # Set up project context"
    echo "  4. /sdd-design \"feature desc\"    # Create a specification"
    echo "  5. /sdd-tasks feature-name       # Generate tasks"
    echo "  6. /sdd-impl feature-name        # Implement with TDD"
fi

echo ""
printf "${BOLD}Update later:${RESET}\n"
echo "  curl -LsSf https://raw.githubusercontent.com/${REPO}/main/install.sh | sh -s -- --update"
