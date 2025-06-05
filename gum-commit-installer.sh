#!/bin/bash

# Gum Conventional Commit Script Installer
# This script installs the Gum-based commit wizard

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}=== Gum Conventional Commit Installer ===${NC}"
echo "This script will install a modern commit wizard using Gum."
echo ""

# Check if gum is installed
if ! command -v gum &>/dev/null; then
  echo -e "${YELLOW}⚠️  Gum is not installed.${NC}"
  echo "Would you like to install it? (requires Homebrew on macOS or manual installation on Linux)"
  echo ""
  echo "Installation options:"
  echo "  macOS: brew install gum"
  echo "  Linux: See https://github.com/charmbracelet/gum#installation"
  echo ""
  read -p "Continue with installation anyway? (y/N): " install_anyway

  if [[ ! $install_anyway =~ ^[Yy]$ ]]; then
    echo -e "${RED}Installation cancelled. Please install gum first.${NC}"
    exit 1
  fi
  echo -e "${YELLOW}Continuing installation (you'll need to install gum manually)...${NC}"
  echo ""
fi

# Improved shell detection
SHELL_TYPE="bash"
SHELL_PATH=$(echo $SHELL)

if [[ "$SHELL_PATH" == *"zsh"* ]]; then
  SHELL_TYPE="zsh"
elif [[ "$SHELL_PATH" == *"bash"* ]]; then
  SHELL_TYPE="bash"
else
  echo -e "${YELLOW}Shell type not automatically detected.${NC}"
  echo "Please select your shell type:"
  echo "1) Bash"
  echo "2) Zsh"
  echo ""
  read -p "Enter selection (1-2): " shell_choice
  case $shell_choice in
  2) SHELL_TYPE="zsh" ;;
  *) SHELL_TYPE="bash" ;;
  esac
fi

echo -e "${BLUE}Using shell: ${YELLOW}$SHELL_TYPE${NC}"
echo ""

# Create script directory if it doesn't exist
mkdir -p ~/.git-scripts

# Remove old git commit wizard if it exists
if [ -f ~/.git-scripts/git-commit-wizard.sh ]; then
  echo -e "${YELLOW}Removing old git commit wizard...${NC}"
  rm ~/.git-scripts/git-commit-wizard.sh
fi

# Create the new gum commit script
echo -e "${BLUE}Creating Gum Conventional Commit script...${NC}"
cat >~/.git-scripts/gum-commit.sh <<'EOF'
#!/bin/bash

# Gum Conventional Commit Script
# Requires: gum (https://github.com/charmbracelet/gum)

set -e

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to display help
show_help() {
    echo -e "${BLUE}Gum Conventional Commit${NC}"
    echo "A modern tool to create standardized commit messages using Gum"
    echo ""
    echo "Usage:"
    echo "  git commit [options]"
    echo ""
    echo "Options:"
    echo "  -a, --all             Commit all changed files"
    echo "  -e, --edit            Open editor for commit message (after wizard)"
    echo "  -v, --verbose         Show diff in commit message editor"
    echo "  -m, --message         Use the provided message with selected type/scope"
    echo "  --amend               Amend previous commit"
    echo "  --no-wizard           Skip the wizard and use normal git commit"
    echo "  -h, --help            Show this help"
    echo ""
    echo "All other git commit options are supported and passed through."
    exit 0
}

# Parse arguments to check for flags
skip_wizard=false
has_message=false
message_value=""
show_help_flag=false

# Loop through all arguments
for ((i = 1; i <= $#; i++)); do
    arg="${!i}"
    
    case "$arg" in
        --help|-h)
            show_help_flag=true
            ;;
        --no-wizard)
            skip_wizard=true
            ;;
        -m|--message)
            has_message=true
            next=$((i + 1))
            if [ $next -le $# ]; then
                message_value="${!next}"
            fi
            ;;
        -m=*|--message=*)
            has_message=true
            message_value="${arg#*=}"
            ;;
    esac
done

# Show help if requested
if [ "$show_help_flag" = true ]; then
    show_help
fi

# If --no-wizard was specified, just pass through to git commit
if [ "$skip_wizard" = true ]; then
    args=()
    for arg in "$@"; do
        if [ "$arg" != "--no-wizard" ]; then
            args+=("$arg")
        fi
    done
    exec git commit "${args[@]}"
    exit $?
fi

# Check if gum is installed
if ! command -v gum &> /dev/null; then
    echo -e "${RED}❌ Error: gum is not installed${NC}"
    echo "Install it with: brew install gum (macOS) or visit https://github.com/charmbracelet/gum"
    echo "Or use: git commit --no-wizard to bypass this script"
    exit 1
fi

# Check if we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Not in a git repository${NC}"
    exit 1
fi

# Check if there are changes to commit (unless amending)
is_amend=false
for arg in "$@"; do
    if [ "$arg" = "--amend" ]; then
        is_amend=true
        break
    fi
done

if [ "$is_amend" = false ] && git diff --cached --quiet && git diff --quiet; then
    echo -e "${RED}❌ No changes to commit${NC}"
    exit 1
fi

echo "🚀 Creating a conventional commit..."
echo

# Check if this is an amend and try to extract previous values
type=""
scope=""
breaking_change=""
message=""

if [ "$is_amend" = true ]; then
    last_commit=$(git log -1 --pretty=%B)
    
    if [[ $last_commit =~ ^([a-z]+)(\([a-zA-Z0-9_-]+\))?(!)?:\ (.*)$ ]]; then
        prev_type="${BASH_REMATCH[1]}"
        prev_scope="${BASH_REMATCH[2]}"
        prev_breaking="${BASH_REMATCH[3]}"
        prev_message="${BASH_REMATCH[4]}"
        
        # Clean up scope (remove parentheses)
        prev_scope="${prev_scope#(}"
        prev_scope="${prev_scope%)}"
        
        echo -e "${BLUE}Previous commit details:${NC}"
        echo -e "Type: ${YELLOW}$prev_type${NC}"
        [ -n "$prev_scope" ] && echo -e "Scope: ${YELLOW}$prev_scope${NC}"
        [ -n "$prev_breaking" ] && echo -e "Breaking: ${YELLOW}Yes${NC}"
        echo -e "Message: ${YELLOW}$prev_message${NC}"
        echo ""
        
        if gum confirm "Reuse these values from previous commit?"; then
            type="$prev_type"
            scope="$prev_scope"
            if [ -n "$prev_breaking" ]; then
                breaking_change="yes"
            fi
            if [ "$has_message" = false ]; then
                message="$prev_message"
            fi
        fi
    fi
fi

# Select commit type (if not already set from amend)
if [ -z "$type" ]; then
    type=$(gum choose \
        "feat" "fix" "docs" "style" "refactor" "test" "chore" "perf" "ci" "build" "revert" \
        --header "Select commit type:")
fi

# Select scope (if not already set from amend)
if [ -z "$scope" ]; then
    echo
    scope=$(gum input --placeholder "Enter scope (optional, press Enter to skip)" --prompt "Scope: " --value "$scope")
fi

# Breaking change (if not already set from amend)
if [ -z "$breaking_change" ]; then
    echo
    if gum confirm "Is this a breaking change?"; then
        breaking_change="yes"
    fi
fi

# Commit description
if [ "$has_message" = true ] && [ -n "$message_value" ]; then
    message="$message_value"
    echo
    echo -e "${BLUE}Using provided commit message: ${YELLOW}$message${NC}"
elif [ -z "$message" ]; then
    echo
    message=$(gum input --placeholder "Brief description of changes" --prompt "Description: " --width 80)
fi

# Optional: Longer description
echo
body=$(gum write --placeholder "Optional longer description (Ctrl+D to finish, Enter to skip)" --header "Extended description:")

# Optional: Issues/tickets
echo
closes=""
if gum confirm "Does this close any issues?"; then
    closes=$(gum input --placeholder "e.g., #123, #456" --prompt "Issues to close: ")
fi

# Build the commit message
commit_msg=""

# Add type and optional scope
if [ -n "$scope" ]; then
    if [ "$breaking_change" = "yes" ]; then
        commit_msg="${type}(${scope})!: ${message}"
    else
        commit_msg="${type}(${scope}): ${message}"
    fi
else
    if [ "$breaking_change" = "yes" ]; then
        commit_msg="${type}!: ${message}"
    else
        commit_msg="${type}: ${message}"
    fi
fi

# Add body if provided
if [ -n "$body" ]; then
    commit_msg="${commit_msg}

${body}"
fi

# Add breaking change footer
if [ "$breaking_change" = "yes" ] && [ -n "$body" ]; then
    echo
    breaking_description=$(gum write --placeholder "Describe the breaking change (Ctrl+D to finish)" --header "Breaking change description:")
    if [ -n "$breaking_description" ]; then
        commit_msg="${commit_msg}

BREAKING CHANGE: ${breaking_description}"
    fi
fi

# Add closes footer
if [ -n "$closes" ]; then
    commit_msg="${commit_msg}

Closes: ${closes}"
fi

# Preview the commit message
echo
gum style --border rounded --padding "1 2" --margin "1 0" \
    --header "📝 Commit Message Preview" \
    "$commit_msg"

echo
if ! gum confirm "Commit these changes?"; then
    echo -e "${RED}❌ Commit cancelled${NC}"
    exit 1
fi

# Build new git arguments without our custom flags
new_args=()
skip_next=false
for arg in "$@"; do
    if [ "$skip_next" = true ]; then
        skip_next=false
        continue
    fi
    
    case "$arg" in
        -m|--message)
            skip_next=true
            continue
            ;;
        -m=*|--message=*)
            continue
            ;;
        --no-wizard|-h|--help)
            continue
            ;;
        *)
            new_args+=("$arg")
            ;;
    esac
done

# Stage all changes if nothing is staged and not amending
if [ "$is_amend" = false ] && git diff --cached --quiet; then
    echo "📦 Staging all changes..."
    git add .
fi

# Check if -e or --edit flag was passed
edit_message=false
for arg in "${new_args[@]}"; do
    if [ "$arg" = "-e" ] || [ "$arg" = "--edit" ]; then
        edit_message=true
        break
    fi
done

# Commit with the formatted message
if [ "$edit_message" = true ]; then
    # Create a temporary file for the commit message
    temp_file=$(mktemp)
    echo "$commit_msg" > "$temp_file"
    
    # Execute git commit with the file and edit flag
    git commit -F "$temp_file" -e "${new_args[@]}"
    exit_code=$?
    
    # Clean up
    rm -f "$temp_file"
else
    # Execute git commit directly
    git commit -m "$commit_msg" "${new_args[@]}"
    exit_code=$?
fi

if [ $exit_code -eq 0 ]; then
    echo -e "${GREEN}✅ Commit created successfully!${NC}"
    echo
    git log -1 --oneline
else
    echo -e "${RED}❌ Commit failed with exit code $exit_code${NC}"
fi

exit $exit_code
EOF

# Make the script executable
chmod +x ~/.git-scripts/gum-commit.sh

# Set up git alias
echo -e "${BLUE}Setting up git alias...${NC}"
git config --global alias.commit '!~/.git-scripts/gum-commit.sh'

# Set shell config file based on detected shell type
if [ "$SHELL_TYPE" = "zsh" ]; then
  SHELL_CONFIG_FILE=~/.zshrc
else
  SHELL_CONFIG_FILE=~/.bashrc
fi

echo -e "${BLUE}Updating shell configuration in ${YELLOW}$SHELL_CONFIG_FILE${NC}"

# Remove old git function if it exists
if grep -q "Git commit wrapper function" "$SHELL_CONFIG_FILE" 2>/dev/null; then
  echo -e "${YELLOW}Removing old git commit wrapper function...${NC}"
  # Create a temporary file without the old function
  temp_file=$(mktemp)
  awk '
        /^# Git commit wrapper function$/ { skip = 1; next }
        /^git\(\) \{$/ && skip { in_function = 1; next }
        /^}$/ && in_function { skip = 0; in_function = 0; next }
        !skip { print }
    ' "$SHELL_CONFIG_FILE" >"$temp_file"
  mv "$temp_file" "$SHELL_CONFIG_FILE"
fi

# Add the new function
if ! grep -q "Gum commit wrapper function" "$SHELL_CONFIG_FILE" 2>/dev/null; then
  cat >>"$SHELL_CONFIG_FILE" <<'EOF'

# Gum commit wrapper function
git() {
    if [[ $1 == "commit" ]]; then
        shift 1
        command ~/.git-scripts/gum-commit.sh "$@"
    else
        command git "$@"
    fi
}
EOF
  echo -e "${GREEN}Function added to $SHELL_CONFIG_FILE${NC}"
else
  echo -e "${YELLOW}Function already exists in $SHELL_CONFIG_FILE. Skipping.${NC}"
fi

echo ""
echo -e "${GREEN}🎉 Gum Conventional Commit has been successfully installed!${NC}"
echo ""
echo -e "${BLUE}Features:${NC}"
echo -e "  ✓ Interactive commit type selection"
echo -e "  ✓ Optional scope and breaking change indicators"
echo -e "  ✓ Extended commit body and issue references"
echo -e "  ✓ Beautiful commit message preview"
echo -e "  ✓ Support for amending with previous values"
echo -e "  ✓ All standard git commit flags supported"
echo ""
echo -e "${BLUE}Usage:${NC}"
echo -e "  ${YELLOW}git commit${NC}           - Start the interactive wizard"
echo -e "  ${YELLOW}git commit --no-wizard${NC} - Skip wizard (normal git commit)"
echo -e "  ${YELLOW}git commit -m \"message\"${NC} - Use wizard for type/scope, provided message"
echo -e "  ${YELLOW}git commit --amend${NC}     - Amend with option to reuse previous values"
echo ""
echo -e "${BLUE}To apply changes to your current shell:${NC}"
echo -e "  ${YELLOW}source $SHELL_CONFIG_FILE${NC}"
echo -e "  ${BLUE}Or start a new terminal session${NC}"

if ! command -v gum &>/dev/null; then
  echo ""
  echo -e "${YELLOW}⚠️  Remember to install gum:${NC}"
  echo -e "  macOS: ${YELLOW}brew install gum${NC}"
  echo -e "  Linux: See https://github.com/charmbracelet/gum#installation"
fi
