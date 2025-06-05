#!/bin/bash

# Conventional Commit Script using Gum
# Requires: gum (https://github.com/charmbracelet/gum)

set -e

# Check if gum is installed
if ! command -v gum &>/dev/null; then
  echo "❌ Error: gum is not installed"
  echo "Install it with: brew install gum (macOS) or visit https://github.com/charmbracelet/gum"
  exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir >/dev/null 2>&1; then
  echo "❌ Error: Not in a git repository"
  exit 1
fi

# Check if there are changes to commit
if git diff --cached --quiet && git diff --quiet; then
  echo "❌ No changes to commit"
  exit 1
fi

echo "🚀 Creating a conventional commit..."
echo

# Select commit type
TYPE=$(gum choose \
  "feat" "fix" "docs" "style" "refactor" "test" "chore" "perf" "ci" "build" "revert" \
  --header "Select commit type:")

# Optional: Select scope
echo
SCOPE=$(gum input --placeholder "Enter scope (optional, press Enter to skip)" --prompt "Scope: ")

# Commit description
echo
DESCRIPTION=$(gum input --placeholder "Brief description of changes" --prompt "Description: " --width 80)

# Optional: Longer description
echo
BODY=$(gum write --placeholder "Optional longer description (Ctrl+D to finish, Enter to skip)" --header "Extended description:")

# Optional: Breaking change
echo
BREAKING_CHANGE=""
if gum confirm "Is this a breaking change?"; then
  BREAKING_CHANGE=$(gum write --placeholder "Describe the breaking change (Ctrl+D to finish)" --header "Breaking change description:")
fi

# Optional: Issues/tickets
echo
CLOSES=""
if gum confirm "Does this close any issues?"; then
  CLOSES=$(gum input --placeholder "e.g., #123, #456" --prompt "Issues to close: ")
fi

# Build the commit message
COMMIT_MSG=""

# Add type and optional scope
if [ -n "$SCOPE" ]; then
  COMMIT_MSG="${TYPE}(${SCOPE}): ${DESCRIPTION}"
else
  COMMIT_MSG="${TYPE}: ${DESCRIPTION}"
fi

# Add breaking change indicator to subject if needed
if [ -n "$BREAKING_CHANGE" ]; then
  if [ -n "$SCOPE" ]; then
    COMMIT_MSG="${TYPE}(${SCOPE})!: ${DESCRIPTION}"
  else
    COMMIT_MSG="${TYPE}!: ${DESCRIPTION}"
  fi
fi

# Add body if provided
if [ -n "$BODY" ]; then
  COMMIT_MSG="${COMMIT_MSG}

${BODY}"
fi

# Add breaking change footer
if [ -n "$BREAKING_CHANGE" ]; then
  COMMIT_MSG="${COMMIT_MSG}

BREAKING CHANGE: ${BREAKING_CHANGE}"
fi

# Add closes footer
if [ -n "$CLOSES" ]; then
  COMMIT_MSG="${COMMIT_MSG}

Closes: ${CLOSES}"
fi

# Preview the commit message
echo
echo "📝 Commit Message Preview"
gum style --border rounded --padding "1 2" --margin "1 0" \
  "$COMMIT_MSG"

echo
if gum confirm "Commit these changes?"; then
  # Stage all changes if nothing is staged
  if git diff --cached --quiet; then
    echo "📦 Staging all changes..."
    git add .
  fi

  # Commit with the formatted message
  git commit -m "$COMMIT_MSG"
  echo "✅ Commit created successfully!"

  # Show the commit
  echo
  git log -1 --oneline
else
  echo "❌ Commit cancelled"
  exit 1
fi
