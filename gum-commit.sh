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
echo "Select commit type:"
echo "1) feat - A new feature"
echo "2) fix - A bug fix"
echo "3) docs - Documentation only changes"
echo "4) style - Changes that do not affect the meaning of the code"
echo "5) refactor - A code change that neither fixes a bug nor adds a feature"
echo "6) test - Adding missing tests or correcting existing tests"
echo "7) chore - Other changes that don't modify src or test files"
echo "8) perf - A code change that improves performance"
echo "9) ci - Changes to CI configuration files and scripts"
echo "10) build - Changes that affect the build system or external dependencies"
echo "11) revert - Reverts a previous commit"
echo

CHOICE=$(gum input --placeholder "Enter number (1-11)" --prompt "Choice: ")

case $CHOICE in
1) TYPE="feat" ;;
2) TYPE="fix" ;;
3) TYPE="docs" ;;
4) TYPE="style" ;;
5) TYPE="refactor" ;;
6) TYPE="test" ;;
7) TYPE="chore" ;;
8) TYPE="perf" ;;
9) TYPE="ci" ;;
10) TYPE="build" ;;
11) TYPE="revert" ;;
*)
  echo "Invalid choice. Defaulting to 'chore'"
  TYPE="chore"
  ;;
esac

# Optional: Select scope
echo
SCOPE=$(gum input --placeholder "Enter scope (optional, press Enter to skip)" --prompt "Scope: ")

# Commit description
echo
DESCRIPTION=$(gum input --placeholder "Brief description of changes" --prompt "Description: " --width 80)

# Optional: Longer description
echo
echo "Extended description (optional):"
BODY=$(gum write --placeholder "Optional longer description (Ctrl+D to finish, Enter to skip)")

# Optional: Breaking change
echo
BREAKING_CHANGE=""
if gum confirm "Is this a breaking change?"; then
  echo "Breaking change description:"
  BREAKING_CHANGE=$(gum write --placeholder "Describe the breaking change (Ctrl+D to finish)")
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

  # Show the commit message that was created
  echo
  echo "📋 Created commit:"
  echo "$COMMIT_MSG"
else
  echo "❌ Commit cancelled"
  exit 1
fi
