#!/bin/sh
set -eu

# sync-sdd installer
# Usage:
#   curl -LsSf https://raw.githubusercontent.com/sync-dev-org/sync-sdd/main/install.sh | sh
#   curl -LsSf https://raw.githubusercontent.com/sync-dev-org/sync-sdd/main/install.sh | sh -s -- --update
#   curl -LsSf https://raw.githubusercontent.com/sync-dev-org/sync-sdd/main/install.sh | sh -s -- --version v0.20.0

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

version_lt() {
    # Returns 0 (true) if $1 < $2, semver comparison
    v1_major=$(echo "$1" | cut -d. -f1)
    v1_minor=$(echo "$1" | cut -d. -f2)
    v1_patch=$(echo "$1" | cut -d. -f3)
    v2_major=$(echo "$2" | cut -d. -f1)
    v2_minor=$(echo "$2" | cut -d. -f2)
    v2_patch=$(echo "$2" | cut -d. -f3)
    : "${v1_patch:=0}" "${v2_patch:=0}"
    [ "$v1_major" -lt "$v2_major" ] && return 0
    [ "$v1_major" -gt "$v2_major" ] && return 1
    [ "$v1_minor" -lt "$v2_minor" ] && return 0
    [ "$v1_minor" -gt "$v2_minor" ] && return 1
    [ "$v1_patch" -lt "$v2_patch" ] && return 0
    return 1
}

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
    --local           Install from local framework/ directory (for development)
    --force           Overwrite existing framework files without prompting
    --uninstall       Remove all SDD framework files
    --help            Show this help message

${BOLD}FRAMEWORK FILES${RESET} (managed by installer):
    .claude/skills/sdd-*/        Skill definitions
    .claude/agents/sdd-*.md      Agent definitions
    .claude/CLAUDE.md            Framework instructions (appended between markers)
    .claude/settings.json        Default settings (prompt before overwrite)

    .claude/sdd/settings/rules/      Development rules
    .claude/sdd/settings/templates/  Spec/steering/knowledge templates
    .claude/sdd/.version             Installed framework version

${BOLD}USER FILES${RESET} (never touched by installer):
    .claude/sdd/project/steering/    Project-specific steering
    .claude/sdd/project/specs/       Feature specifications
    .claude/sdd/project/knowledge/   Knowledge base entries
    .claude/sdd/handover/            Session continuity (auto-persisted)
    .claude/settings.local.json      Local setting overrides

${BOLD}CHECK VERSION${RESET}:
    cat .claude/sdd/.version
EOF
    exit 0
}

# --- Parse arguments ---
UPDATE=false
FORCE=false
UNINSTALL=false
LOCAL=false
VERSION=""

while [ $# -gt 0 ]; do
    case "$1" in
        --update)    UPDATE=true ;;
        --force)     FORCE=true ;;
        --uninstall) UNINSTALL=true ;;
        --local)     LOCAL=true ;;
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
    rm -rf .claude/skills/sdd-*/
    rm -f .claude/commands/sdd-*.md   # legacy cleanup
    rm -f .claude/agents/sdd-*.md
    rm -rf .claude/sdd/settings/rules/ \
           .claude/sdd/settings/templates/
    rm -f .claude/sdd/.version

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
    rmdir .claude/skills .claude/commands .claude/agents .claude/sdd/settings .claude/sdd 2>/dev/null || true

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

# --- Source resolution ---
if [ "$LOCAL" = true ]; then
    # Local mode: use framework/ from current directory
    if [ ! -d "framework" ]; then
        error "No framework/ directory found. Run --local from the sync-sdd repository root."
        exit 1
    fi
    SRC="."
    info "Installing from local framework/ directory..."
else
    # Remote mode: download from GitHub
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
fi

# --- Read versions ---
if [ -f "$SRC/VERSION" ]; then
    NEW_VERSION=$(tr -d '[:space:]' < "$SRC/VERSION")
else
    NEW_VERSION="0.0.0"
fi
if [ -f .claude/sdd/.version ]; then
    read -r INSTALLED_VERSION < .claude/sdd/.version
else
    INSTALLED_VERSION="0.0.0"
fi
if [ "$NEW_VERSION" != "0.0.0" ] && [ "$INSTALLED_VERSION" != "0.0.0" ]; then
    info "Version: ${INSTALLED_VERSION} -> ${NEW_VERSION}"
elif [ "$NEW_VERSION" != "0.0.0" ]; then
    info "Version: ${NEW_VERSION}"
fi

# --- Migrations ---
migrate_kiro_to_sdd() {
    [ -d .kiro ] || return 0
    info "Detected legacy .kiro/ directory"
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
    rm -rf .kiro/settings/rules/ .kiro/settings/templates/
    rmdir .kiro/settings .kiro 2>/dev/null || true
    if [ -d .kiro ]; then
        warn ".kiro/ still has files; check manually"
    else
        success "Legacy .kiro/ directory fully migrated"
    fi
    UPDATE=true
    if [ -f .claude/CLAUDE.md ] && ! grep -q "$SDD_MARKER_START" .claude/CLAUDE.md; then
        rm -f .claude/CLAUDE.md
        info "Removed legacy CLAUDE.md (will be recreated with markers)"
    fi
}

# Run migrations in version order
if version_lt "$INSTALLED_VERSION" "0.4.0"; then
    migrate_kiro_to_sdd
fi
# v0.7.0: Coordinator eliminated, 3-tier architecture
if version_lt "$INSTALLED_VERSION" "0.7.0"; then
    if [ -f .claude/agents/sdd-coordinator.md ]; then
        rm -f .claude/agents/sdd-coordinator.md
        info "Removed sdd-coordinator.md (3-tier architecture in v0.7.0)"
    fi
    if [ -f .claude/sdd/handover/coordinator.md ]; then
        if [ -f .claude/sdd/handover/conductor.md ]; then
            printf '\n\n## Migrated Pipeline State\n\n' >> .claude/sdd/handover/conductor.md
            cat .claude/sdd/handover/coordinator.md >> .claude/sdd/handover/conductor.md
            info "Merged coordinator handover state into conductor.md"
        else
            mv .claude/sdd/handover/coordinator.md .claude/sdd/handover/conductor.md
            info "Renamed coordinator handover to conductor.md"
        fi
        rm -f .claude/sdd/handover/coordinator.md
    fi
fi
# v0.9.0: Handover redesign - state.md → session.md, log.md → decisions.md
if version_lt "$INSTALLED_VERSION" "0.9.0"; then
    if [ -f .claude/sdd/handover/conductor.md ]; then
        mv .claude/sdd/handover/conductor.md .claude/sdd/handover/session.md
        info "Renamed handover/conductor.md -> session.md (v0.9.0)"
    elif [ -f .claude/sdd/handover/state.md ]; then
        mv .claude/sdd/handover/state.md .claude/sdd/handover/session.md
        info "Renamed handover/state.md -> session.md (v0.9.0)"
    fi
    if [ -f .claude/sdd/handover/log.md ]; then
        mv .claude/sdd/handover/log.md .claude/sdd/handover/decisions.md
        info "Renamed handover/log.md -> decisions.md (v0.9.0)"
    fi
fi
# v0.10.0: Format unification (spec.json→spec.yaml) + Planner elimination
if version_lt "$INSTALLED_VERSION" "0.10.0"; then
    info "Migrating to v0.10.0..."

    # Remove obsolete framework files
    rm -f .claude/agents/sdd-planner.md
    rm -f .claude/commands/sdd-tasks.md
    rm -f .claude/sdd/settings/templates/specs/tasks.md
    rm -f .claude/sdd/settings/templates/specs/init.json

    # Convert existing spec.json → spec.yaml for all specs
    if [ -d .claude/sdd/project/specs ]; then
        for spec_dir in .claude/sdd/project/specs/*/; do
            [ -d "$spec_dir" ] || continue
            if [ -f "$spec_dir/spec.json" ]; then
                info "Converting ${spec_dir}spec.json → spec.yaml"
                # Best-effort JSON→YAML conversion using sed/awk
                # Adds orchestration and blocked_info fields, removes version_refs.tasks
                sed -e 's/^{$//' -e 's/^}$//' \
                    -e 's/"feature_name": "\(.*\)",$/feature_name: "\1"/' \
                    -e 's/"created_at": "\(.*\)",$/created_at: "\1"/' \
                    -e 's/"updated_at": "\(.*\)",$/updated_at: "\1"/' \
                    -e 's/"language": "\(.*\)",$/language: "\1"/' \
                    -e 's/"version": "\(.*\)",$/version: "\1"/' \
                    -e 's/"changelog": \[\],$/changelog: []/' \
                    -e 's/"changelog": \[$/changelog:/' \
                    -e 's/"version_refs": {$/version_refs:/' \
                    -e 's/"design": null$/  design: null/' \
                    -e 's/"design": "\(.*\)"$/  design: "\1"/' \
                    -e '/\"tasks\"/d' \
                    -e 's/},$//' \
                    -e 's/"phase": "\(.*\)",$/phase: "\1"/' \
                    -e 's/"phase": "\(.*\)"$/phase: "\1"/' \
                    -e 's/"implementation": {$/implementation:/' \
                    -e 's/"files_created": \[\]$/  files_created: []/' \
                    -e 's/"roadmap": null$/roadmap: null/' \
                    -e '/^[[:space:]]*$/d' \
                    -e '/^[[:space:]]*[{}],\?$/d' \
                    "$spec_dir/spec.json" > "$spec_dir/spec.yaml"
                # Append new fields
                printf 'orchestration:\n  retry_count: 0\n  spec_update_count: 0\n  last_phase_action: null\nblocked_info: null\n' >> "$spec_dir/spec.yaml"
                rm "$spec_dir/spec.json"
            fi
        done
    fi

    # tasks.md files are left as-is; TaskGenerator will regenerate on next /sdd-impl run
    info "v0.10.0 migration complete."
    info "Note: Existing tasks.md files are preserved but will be regenerated by TaskGenerator on next /sdd-impl run."
fi
# v0.15.0: Commands → Skills directory migration
if version_lt "$INSTALLED_VERSION" "0.15.0"; then
    for cmd_file in .claude/commands/sdd-*.md; do
        [ -f "$cmd_file" ] || continue
        rm -f "$cmd_file"
    done
    if [ -d .claude/commands ] && [ -z "$(ls -A .claude/commands 2>/dev/null)" ]; then
        rmdir .claude/commands 2>/dev/null || true
    fi
    info "Migrated commands -> skills format (v0.15.0)"
fi
# v0.18.0: Agent definitions moved from .claude/agents/ to .claude/sdd/settings/agents/
if version_lt "$INSTALLED_VERSION" "0.18.0"; then
    for agent_file in .claude/agents/sdd-*.md; do
        [ -f "$agent_file" ] || continue
        rm -f "$agent_file"
    done
    if [ -d .claude/agents ] && [ -z "$(ls -A .claude/agents 2>/dev/null)" ]; then
        rmdir .claude/agents 2>/dev/null || true
    fi
    info "Migrated agents/ -> sdd/settings/agents/ (v0.18.0)"
fi
# v0.20.0: Agent definitions moved from .claude/sdd/settings/agents/ to .claude/agents/
# Also: Agent Teams env var no longer needed
if version_lt "$INSTALLED_VERSION" "0.20.0"; then
    if [ -d ".claude/sdd/settings/agents" ]; then
        mkdir -p .claude/agents
        for agent_file in .claude/sdd/settings/agents/sdd-*.md; do
            [ -f "$agent_file" ] || continue
            mv "$agent_file" ".claude/agents/$(basename "$agent_file")"
        done
        rmdir .claude/sdd/settings/agents 2>/dev/null || true
        info "Migrated sdd/settings/agents/ -> .claude/agents/ (v0.20.0)"
    fi
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
install_dir "$SRC/framework/claude/skills" ".claude/skills"

# .claude/CLAUDE.md - marker-based section management
install_claude_md() {
    src_file="$1"
    dest=".claude/CLAUDE.md"
    mkdir -p .claude

    # Inject version into content and build marked block
    claude_content=$(sed "s/{{SDD_VERSION}}/${NEW_VERSION}/g" "$src_file")
    marked_block="$SDD_MARKER_START
${claude_content}
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
        fi
    fi
else
    install_file "$SRC/framework/claude/settings.json" ".claude/settings.json"
fi

# .claude/sdd/settings/ framework files
install_dir "$SRC/framework/claude/sdd/settings/rules"     ".claude/sdd/settings/rules"
install_dir "$SRC/framework/claude/sdd/settings/templates"  ".claude/sdd/settings/templates"
install_dir "$SRC/framework/claude/sdd/settings/profiles"   ".claude/sdd/settings/profiles"
install_dir "$SRC/framework/claude/agents"     ".claude/agents"

# Write version file
if [ "$NEW_VERSION" != "0.0.0" ]; then
    mkdir -p .claude/sdd
    printf '%s\n' "$NEW_VERSION" > .claude/sdd/.version
fi

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

    # Skills: scope to sdd-* directories only (preserve user-created skills)
    for skill_dir in .claude/skills/sdd-*/; do
        [ -d "$skill_dir" ] || continue
        rel="${skill_dir#.claude/skills/}"
        if [ ! -d "$SRC/framework/claude/skills/$rel" ]; then
            rm -rf "$skill_dir"
            warn "Removed stale skill: $skill_dir"
        fi
    done
    remove_stale ".claude/sdd/settings/rules"     "$SRC/framework/claude/sdd/settings/rules"     "*.md"
    remove_stale ".claude/sdd/settings/templates" "$SRC/framework/claude/sdd/settings/templates"  "*"
    remove_stale ".claude/sdd/settings/profiles"  "$SRC/framework/claude/sdd/settings/profiles"   "*.md"
    remove_stale ".claude/agents"    "$SRC/framework/claude/agents"     "*.md"

    # Clean up empty directories left after stale file removal
    find .claude/sdd/settings/templates -depth -type d -empty -delete 2>/dev/null || true
    find .claude/sdd/settings/profiles -depth -type d -empty -delete 2>/dev/null || true
    find .claude/skills -depth -type d -empty -delete 2>/dev/null || true
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
echo "  .claude/skills/      $(find .claude/skills -name 'SKILL.md' -path '*/sdd-*/*' 2>/dev/null | wc -l | tr -d ' ') skills"
echo "  .claude/agents/      $(find .claude/agents -name 'sdd-*.md' 2>/dev/null | wc -l | tr -d ' ') agent profiles"
echo "  .claude/CLAUDE.md    Framework instructions (marker-managed)"
echo "  .claude/sdd/         Rules + templates"
if [ "$NEW_VERSION" != "0.0.0" ]; then
    echo "  Version:             ${NEW_VERSION}"
fi

if [ "$UPDATE" = false ]; then
    echo ""
    printf "${BOLD}Quick start:${RESET}\n"
    echo "  1. cd your-project"
    echo "  2. claude                             # Start Claude Code"
    echo "  3. /sdd-steering                      # Set up project context"
    echo "  4. /sdd-roadmap design \"feature desc\" # Create a specification"
    echo "  5. /sdd-roadmap impl feature-name     # Implement with TDD"
fi

echo ""
printf "${BOLD}Update later:${RESET}\n"
echo "  curl -LsSf https://raw.githubusercontent.com/${REPO}/main/install.sh | sh -s -- --update"
