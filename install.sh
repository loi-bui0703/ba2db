#!/usr/bin/env bash
# ba2db installer — for users without Node, or who prefer git.
#
#   curl -fsSL https://raw.githubusercontent.com/loi-bui0703/ba2db/main/install.sh | bash
#   ./install.sh --host claude-code --global
set -euo pipefail

REPO="https://github.com/loi-bui0703/ba2db.git"
SKILL_NAME="ba2db"
HOST=""
SCOPE=""
FORCE=0

usage() {
  cat <<'USAGE'
ba2db installer

Usage: ./install.sh [--host <id>] [--global|--project] [--force]

Hosts:  claude-code | cursor | codex | copilot | opencode | generic
Scope:  --global  installs for the current user (where supported)
        --project installs into the current directory

With no --host, the script detects what is on this machine and asks.
USAGE
}

while [ $# -gt 0 ]; do
  case "$1" in
    --host) HOST="${2:-}"; shift 2 ;;
    --global) SCOPE="global"; shift ;;
    --project) SCOPE="project"; shift ;;
    --force) FORCE=1; shift ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown option: $1" >&2; usage >&2; exit 1 ;;
  esac
done

# Locate the skill: either we are inside a clone, or we make a temp one.
if [ -f "$(dirname "$0")/skill/SKILL.md" ]; then
  SRC="$(cd "$(dirname "$0")/skill" && pwd)"
else
  command -v git >/dev/null || { echo "git is required when not running from a clone." >&2; exit 1; }
  TMP="$(mktemp -d)"
  trap 'rm -rf "$TMP"' EXIT
  echo "Cloning $REPO ..."
  git clone --depth 1 --quiet "$REPO" "$TMP/ba2db"
  SRC="$TMP/ba2db/skill"
fi

detect() {
  local found=()
  [ -d "$HOME/.claude" ] && found+=("claude-code")
  { [ -d "$HOME/.cursor" ] || [ -d ".cursor" ]; } && found+=("cursor")
  { [ -f "AGENTS.md" ] || [ -d "$HOME/.codex" ]; } && found+=("codex")
  [ -d ".github" ] && found+=("copilot")
  [ -f "opencode.json" ] && found+=("opencode")
  printf '%s\n' "${found[@]:-}"
}

if [ -z "$HOST" ]; then
  mapfile -t DETECTED < <(detect)
  if [ "${#DETECTED[@]}" -eq 0 ] || [ -z "${DETECTED[0]}" ]; then
    echo "No known agent host detected — installing in manual mode."
    HOST="generic"
  else
    echo "Detected: ${DETECTED[*]}"
    if [ -t 0 ]; then
      read -r -p "Install for which host? [${DETECTED[0]}] " reply
      HOST="${reply:-${DETECTED[0]}}"
    else
      HOST="${DETECTED[0]}"
      echo "Non-interactive — choosing $HOST"
    fi
  fi
fi

place_skill() {
  local dest="$1"
  if [ -e "$dest" ] && [ "$FORCE" -eq 0 ]; then
    echo "Already installed at $dest — re-run with --force to overwrite." >&2
    exit 1
  fi
  rm -rf "$dest"
  mkdir -p "$(dirname "$dest")"
  cp -R "$SRC" "$dest"
  echo "  skill → $dest"
}

# A rule file points at the skill; it never duplicates its content.
rule_body() {
  local path="$1"
  cat <<RULE
When the user asks to design a database, extract data requirements from
business/BA documents, build an ERD, normalize a schema, or generate DDL:
read \`$path/SKILL.md\` first and follow its six-stage workflow.

Rules that matter:
- Do not jump straight to DDL. Each stage produces its own artifact.
- Load only the SKILL.md of the stage you are working on.
- Every entity, attribute and rule must cite its source in the BA documents.
  Missing information becomes an OPEN QUESTION — never invent business facts.
- Stop at the gate at the end of each stage and ask the user to confirm.
- Table and column names are English snake_case; prose may be EN/VI.
RULE
}

append_block() {
  local file="$1" body="$2"
  mkdir -p "$(dirname "$file")"
  touch "$file"
  if grep -q "<!-- ${SKILL_NAME}:begin -->" "$file" 2>/dev/null; then
    echo "  rule  → $file (already present, left unchanged)"
    return
  fi
  { printf '\n<!-- %s:begin -->\n' "$SKILL_NAME"; printf '%s\n' "$body"; printf '<!-- %s:end -->\n' "$SKILL_NAME"; } >> "$file"
  echo "  rule  → $file (appended)"
}

echo ""
case "$HOST" in
  claude-code)
    if [ "$SCOPE" = "project" ]; then dest=".claude/skills/$SKILL_NAME"; else dest="$HOME/.claude/skills/$SKILL_NAME"; fi
    place_skill "$dest"
    ;;
  cursor)
    place_skill ".$SKILL_NAME"
    mkdir -p ".cursor/rules"
    { echo "---"; echo "description: Database design from BA documents (ba2db)"; echo "alwaysApply: false"; echo "---"; echo ""; rule_body ".$SKILL_NAME"; } > ".cursor/rules/$SKILL_NAME.mdc"
    echo "  rule  → .cursor/rules/$SKILL_NAME.mdc"
    ;;
  codex)
    place_skill ".$SKILL_NAME"
    append_block "AGENTS.md" "## Database design from BA documents (ba2db)

$(rule_body ".$SKILL_NAME")"
    ;;
  copilot)
    place_skill ".$SKILL_NAME"
    append_block ".github/copilot-instructions.md" "## Database design from BA documents (ba2db)

$(rule_body ".$SKILL_NAME")"
    ;;
  opencode)
    place_skill ".$SKILL_NAME"
    mkdir -p ".opencode/rules"
    rule_body ".$SKILL_NAME" > ".opencode/rules/$SKILL_NAME.md"
    echo "  rule  → .opencode/rules/$SKILL_NAME.md"
    ;;
  generic)
    place_skill ".$SKILL_NAME"
    echo ""
    echo "Manual mode. Paste this into your agent:"
    echo "---"
    echo "Read .$SKILL_NAME/SKILL.md and follow its six-stage workflow to design a"
    echo "database from my BA documents in <path>. Start at Stage 0."
    echo "---"
    ;;
  *)
    echo "Unknown host: $HOST" >&2
    exit 1
    ;;
esac

echo ""
echo "✓ ba2db installed for $HOST"
echo "  Next: create a workspace →  bash <skill>/scripts/init-workspace.sh <project-slug>"
