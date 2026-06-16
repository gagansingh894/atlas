#!/usr/bin/env bash
set -e

REPO="gagandeepsingh94/atlas"
BRANCH="main"
GITHUB_RAW="https://raw.githubusercontent.com/$REPO/$BRANCH"

# Detect if running locally (clone) or remotely (curl | bash)
SCRIPT_PATH="${BASH_SOURCE[0]}"
if [ -n "$SCRIPT_PATH" ] && [ -f "$SCRIPT_PATH" ]; then
  ATLAS_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
  LOCAL=true
else
  LOCAL=false
fi

INTEGRATION="claude-code"
PER_REPO=false
REPO_ROOT=""
MODE="skill"

for arg in "$@"; do
  case $arg in
    --integration=*)
      INTEGRATION="${arg#*=}"
      ;;
    --per-repo)
      PER_REPO=true
      ;;
    --repo=*)
      REPO_ROOT="${arg#*=}"
      ;;
    --full)
      MODE="full"
      ;;
    --skill)
      MODE="skill"
      ;;
    --help|-h)
      echo "Usage: install.sh [--integration=<name>] [--per-repo] [--repo=<path>] [--full|--skill]"
      echo ""
      echo "  --skill      Install as a single self-contained atlas skill (default)"
      echo "  --full       Install 5 commands + 5 individual skills (classic mode)"
      echo "  --per-repo   Install into .claude/ instead of ~/.claude/"
      exit 0
      ;;
  esac
done

# Validate integration
VALID_INTEGRATIONS=("claude-code")
VALID=false
for i in "${VALID_INTEGRATIONS[@]}"; do
  [ "$i" = "$INTEGRATION" ] && VALID=true && break
done
if [ "$VALID" = false ]; then
  echo "Error: no integration found for '$INTEGRATION'."
  echo ""
  echo "Available integrations:"
  for i in "${VALID_INTEGRATIONS[@]}"; do
    echo "  $i"
  done
  echo ""
  echo "Usage: install.sh [--integration=<name>] [--per-repo] [--repo=<path>] [--full|--skill]"
  exit 1
fi

# Resolve install targets
if [ "$PER_REPO" = true ]; then
  ROOT="${REPO_ROOT:-$(pwd)}"
  TARGET_COMMANDS="$ROOT/.claude/commands"
  TARGET_SKILLS="$ROOT/.claude/skills"
  echo "Installing Atlas (Claude Code) into $ROOT/.claude/ ..."
else
  CLAUDE_DIR="$HOME/.claude"
  TARGET_COMMANDS="$CLAUDE_DIR/commands"
  TARGET_SKILLS="$CLAUDE_DIR/skills"
  echo "Installing Atlas (Claude Code) globally into $CLAUDE_DIR ..."
fi

mkdir -p "$TARGET_SKILLS"

# Helper: fetch a file either from local clone or GitHub
fetch_file() {
  local rel_path="$1"   # relative to repo root
  local dest="$2"
  if [ "$LOCAL" = true ] && [ -f "$ATLAS_DIR/$rel_path" ]; then
    cp "$ATLAS_DIR/$rel_path" "$dest"
  else
    curl -fsSL "$GITHUB_RAW/$rel_path" -o "$dest"
  fi
}

BASE="integrations/$INTEGRATION"

if [ "$MODE" = "skill" ]; then
  mkdir -p "$TARGET_SKILLS/atlas"
  fetch_file "$BASE/skills/atlas/SKILL.md" "$TARGET_SKILLS/atlas/SKILL.md"

  echo ""
  echo "Atlas installed successfully (single-skill mode)."
  echo "  Skill: atlas  →  $TARGET_SKILLS/atlas/SKILL.md"
  echo ""
  echo "The atlas skill handles all operations:"
  echo "  - Codebase Overview    (generate .atlas/codebase-index.json + .atlas/codebase-overview.md)"
  echo "  - Ask Atlas            (Q&A from pre-built docs, no re-traversal)"
  echo "  - Architecture Diagram (draw.io, Excalidraw, Mermaid)"
  echo "  - ML Overview          (.atlas/ml-overview.md)"
  echo "  - Ecosystem Overview   (cross-repo dependency map)"
  echo ""
  echo "Usage examples:"
  echo "  \"Document this codebase\"           → runs Codebase Overview"
  echo "  \"How does the auth flow work?\"      → runs Ask Atlas"
  echo "  \"Generate an architecture diagram\" → runs Architecture Diagram"
  echo ""
  echo "To reinstall with separate commands + skills: install.sh --full"

else
  mkdir -p "$TARGET_COMMANDS"

  COMMANDS=(
    "architecture-diagram"
    "ask-atlas"
    "codebase-overview"
    "ecosystem-overview"
    "ml-overview"
  )
  COMMANDS_INSTALLED=0
  for cmd in "${COMMANDS[@]}"; do
    fetch_file "$BASE/commands/$cmd.md" "$TARGET_COMMANDS/$cmd.md"
    COMMANDS_INSTALLED=$((COMMANDS_INSTALLED + 1))
  done

  INDIVIDUAL_SKILLS=(
    "detect-git-changes"
    "domain-models"
    "explore-repo-interface"
    "generate-diagram"
    "index-codebase"
    "write-overview-doc"
  )
  SKILLS_INSTALLED=0
  for skill in "${INDIVIDUAL_SKILLS[@]}"; do
    mkdir -p "$TARGET_SKILLS/$skill"
    fetch_file "$BASE/skills/$skill/SKILL.md" "$TARGET_SKILLS/$skill/SKILL.md"
    SKILLS_INSTALLED=$((SKILLS_INSTALLED + 1))
  done

  echo ""
  echo "Atlas installed successfully (full mode)."
  echo "  Commands : $COMMANDS_INSTALLED  →  $TARGET_COMMANDS"
  echo "  Skills   : $SKILLS_INSTALLED  →  $TARGET_SKILLS"
  echo ""
  echo "Available commands:"
  for cmd in "${COMMANDS[@]}"; do
    echo "  /$cmd"
  done
  echo ""
  echo "To install as a single skill instead: install.sh --skill"
fi

if [ "$PER_REPO" = true ]; then
  echo "Tip: commit .claude/ so the whole team gets Atlas automatically."
  echo "  git add .claude/ && git commit -m \"Add Atlas\""
fi
