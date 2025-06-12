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

# Parse command line arguments
COMMIT_MESSAGE=""
SHOULD_AMEND=false
SHOULD_EDIT=false
NO_WIZARD=false
STAGE_ALL=false
VERBOSE=false
OTHER_ARGS=()

while [[ $# -gt 0 ]]; do
  case $1 in
  -m | --message)
    COMMIT_MESSAGE="$2"
    shift 2
    ;;
  --amend)
    SHOULD_AMEND=true
    shift
    ;;
  -e | --edit)
    SHOULD_EDIT=true
    shift
    ;;
  --no-wizard)
    NO_WIZARD=true
    shift
    ;;
  -a | --all)
    STAGE_ALL=true
    shift
    ;;
  -v | --verbose)
    VERBOSE=true
    shift
    ;;
  *)
    OTHER_ARGS+=("$1")
    shift
    ;;
  esac
done

# If --no-wizard is specified, use standard git commit
if [ "$NO_WIZARD" = true ]; then
  git_args=()

  if [ -n "$COMMIT_MESSAGE" ]; then
    git_args+=("-m" "$COMMIT_MESSAGE")
  fi

  if [ "$SHOULD_AMEND" = true ]; then
    git_args+=("--amend")
  fi

  if [ "$SHOULD_EDIT" = true ]; then
    git_args+=("-e")
  fi

  if [ "$STAGE_ALL" = true ]; then
    git_args+=("-a")
  fi

  if [ "$VERBOSE" = true ]; then
    git_args+=("-v")
  fi

  # Add any other arguments
  git_args+=("${OTHER_ARGS[@]}")

  exec git commit "${git_args[@]}"
fi

# Initialize variables for extracted values (used for amend)
PREV_TYPE=""
PREV_SCOPE=""
PREV_DESCRIPTION=""
PREV_BODY=""
PREV_BREAKING_CHANGE=""
PREV_CLOSES=""

# If amending, try to extract information from the previous commit
if [ "$SHOULD_AMEND" = true ]; then
  PREV_COMMIT_MSG=$(git log -1 --pretty=%B)

  # Try to parse the previous commit message using a simpler approach
  if [[ -n "$PREV_COMMIT_MSG" ]]; then
    # Get the first line
    FIRST_LINE=$(echo "$PREV_COMMIT_MSG" | head -n 1)

    # Simple parsing without regex - check if it looks like conventional commit
    if [[ "$FIRST_LINE" == *": "* ]]; then
      # Extract the part before the colon
      TYPE_PART=$(echo "$FIRST_LINE" | cut -d':' -f1)

      # Extract type - remove ! if present
      PREV_TYPE=$(echo "$TYPE_PART" | sed 's/!$//')

      # Check if there's a scope (contains parentheses)
      if [[ "$TYPE_PART" == *"("* ]] && [[ "$TYPE_PART" == *")"* ]]; then
        # Extract scope from between parentheses
        PREV_SCOPE=$(echo "$TYPE_PART" | sed 's/.*(//' | sed 's/).*//')
        # Remove scope part to get clean type
        PREV_TYPE=$(echo "$PREV_TYPE" | sed 's/(.*//')
      fi

      # Extract description (everything after first colon and space)
      PREV_DESCRIPTION=$(echo "$FIRST_LINE" | cut -d':' -f2- | sed 's/^ *//')

      # Get the rest of the commit message
      COMMIT_REST=$(echo "$PREV_COMMIT_MSG" | tail -n +3)

      # Look for breaking change (simple grep approach)
      if echo "$COMMIT_REST" | grep -q "^BREAKING CHANGE:"; then
        PREV_BREAKING_CHANGE=$(echo "$COMMIT_REST" | grep "^BREAKING CHANGE:" | sed 's/^BREAKING CHANGE: *//')
      fi

      # Look for closes
      if echo "$COMMIT_REST" | grep -q "^Closes:"; then
        PREV_CLOSES=$(echo "$COMMIT_REST" | grep "^Closes:" | sed 's/^Closes: *//')
      fi

      # Get body (everything before BREAKING CHANGE or Closes)
      PREV_BODY=$(echo "$COMMIT_REST" | sed '/^BREAKING CHANGE:/,$d' | sed '/^Closes:/,$d' | sed '/^$/d')
    fi
  fi
fi

# Check if there are changes to commit (skip for amend)
if [ "$SHOULD_AMEND" = false ]; then
  if git diff --cached --quiet && git diff --quiet; then
    echo "❌ No changes to commit"
    exit 1
  fi
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

# Use previous type as default if amending
DEFAULT_TYPE_CHOICE=""
if [ -n "$PREV_TYPE" ]; then
  case $PREV_TYPE in
  feat) DEFAULT_TYPE_CHOICE="1" ;;
  fix) DEFAULT_TYPE_CHOICE="2" ;;
  docs) DEFAULT_TYPE_CHOICE="3" ;;
  style) DEFAULT_TYPE_CHOICE="4" ;;
  refactor) DEFAULT_TYPE_CHOICE="5" ;;
  test) DEFAULT_TYPE_CHOICE="6" ;;
  chore) DEFAULT_TYPE_CHOICE="7" ;;
  perf) DEFAULT_TYPE_CHOICE="8" ;;
  ci) DEFAULT_TYPE_CHOICE="9" ;;
  build) DEFAULT_TYPE_CHOICE="10" ;;
  revert) DEFAULT_TYPE_CHOICE="11" ;;
  esac

  if [ -n "$DEFAULT_TYPE_CHOICE" ]; then
    CHOICE=$(gum input --placeholder "Enter number (1-11)" --prompt "Choice: " --value "$DEFAULT_TYPE_CHOICE")
  else
    CHOICE=$(gum input --placeholder "Enter number (1-11)" --prompt "Choice: ")
  fi
else
  CHOICE=$(gum input --placeholder "Enter number (1-11)" --prompt "Choice: ")
fi

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
if [ -n "$PREV_SCOPE" ]; then
  SCOPE=$(gum input --placeholder "Enter scope (optional, press Enter to skip)" --prompt "Scope: " --value "$PREV_SCOPE")
else
  SCOPE=$(gum input --placeholder "Enter scope (optional, press Enter to skip)" --prompt "Scope: ")
fi

# Commit description
echo
if [ -n "$COMMIT_MESSAGE" ]; then
  # Use the provided message from -m flag
  DESCRIPTION="$COMMIT_MESSAGE"
  echo "Using provided message: $DESCRIPTION"
elif [ -n "$PREV_DESCRIPTION" ]; then
  # Use previous description as default if amending
  DESCRIPTION=$(gum input --placeholder "Brief description of changes" --prompt "Description: " --width 80 --value "$PREV_DESCRIPTION")
else
  DESCRIPTION=$(gum input --placeholder "Brief description of changes" --prompt "Description: " --width 80)
fi

# Validate that description is not empty
if [ -z "$DESCRIPTION" ]; then
  echo "❌ Error: Description cannot be empty"
  exit 1
fi

# Optional: Longer description
echo
echo "Extended description (optional):"
if [ -n "$PREV_BODY" ]; then
  BODY=$(gum write --placeholder "Optional longer description (Ctrl+D to finish, Enter to skip)" --value "$PREV_BODY")
else
  BODY=$(gum write --placeholder "Optional longer description (Ctrl+D to finish, Enter to skip)")
fi

# Optional: Breaking change
echo
BREAKING_CHANGE=""
if [ -n "$PREV_BREAKING_CHANGE" ]; then
  if gum confirm "Is this a breaking change?" --default=true; then
    echo "Breaking change description:"
    BREAKING_CHANGE=$(gum write --placeholder "Describe the breaking change (Ctrl+D to finish)" --value "$PREV_BREAKING_CHANGE")
  fi
else
  if gum confirm "Is this a breaking change?"; then
    echo "Breaking change description:"
    BREAKING_CHANGE=$(gum write --placeholder "Describe the breaking change (Ctrl+D to finish)")
  fi
fi

# Optional: Issues/tickets
echo
CLOSES=""
if [ -n "$PREV_CLOSES" ]; then
  if gum confirm "Does this close any issues?" --default=true; then
    CLOSES=$(gum input --placeholder "e.g., #123, #456" --prompt "Issues to close: " --value "$PREV_CLOSES")
  fi
else
  if gum confirm "Does this close any issues?"; then
    CLOSES=$(gum input --placeholder "e.g., #123, #456" --prompt "Issues to close: ")
  fi
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
  # Prepare git commit arguments
  git_args=()

  if [ "$SHOULD_AMEND" = true ]; then
    git_args+=("--amend")
  fi

  if [ "$VERBOSE" = true ]; then
    git_args+=("-v")
  fi

  # Add any other arguments
  git_args+=("${OTHER_ARGS[@]}")

  # Stage all changes if nothing is staged and we're not amending
  if [ "$SHOULD_AMEND" = false ]; then
    if [ "$STAGE_ALL" = true ] || git diff --cached --quiet; then
      echo "📦 Staging all changes..."
      git add .
    fi
  fi

  # Commit with the formatted message
  if [ "$SHOULD_EDIT" = true ]; then
    # Create a temporary file with the commit message
    TEMP_FILE=$(mktemp)
    echo "$COMMIT_MSG" >"$TEMP_FILE"
    git commit "${git_args[@]}" --file="$TEMP_FILE" --edit
    rm "$TEMP_FILE"
  else
    git commit "${git_args[@]}" -m "$COMMIT_MSG"
  fi

  echo "✅ Commit created successfully!"

  # Show the commit message that was created
  echo
  echo "📋 Created commit:"
  echo "$COMMIT_MSG"
else
  echo "❌ Commit cancelled"
  exit 1
fi
