#!/bin/bash

# Gum Conventional Commit Installer
# A modern interactive commit message tool using Gum

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Gum Conventional Commit Installer${NC}"
echo ""
echo "This installer will set up an interactive commit message wizard that helps you"
echo "create standardized commit messages following conventional commit format."
echo ""

# Check if gum is installed
if ! command -v gum &>/dev/null; then
  echo -e "${YELLOW}📦 Gum is required but not installed.${NC}"
  echo ""
  echo "Gum is a modern CLI tool for beautiful interactive prompts."
  echo "Installation options:"
  echo ""
  echo -e "  ${BLUE}macOS:${NC}     brew install gum"
  echo -e "  ${BLUE}Linux:${NC}     See https://github.com/charmbracelet/gum#installation"
  echo -e "  ${BLUE}Windows:${NC}   See https://github.com/charmbracelet/gum#installation"
  echo ""
  read -p "Would you like to continue installation anyway? (y/N): " install_anyway

  if [[ ! $install_anyway =~ ^[Yy]$ ]]; then
    echo -e "${RED}Installation cancelled. Please install gum first and try again.${NC}"
    exit 1
  fi
  echo -e "${YELLOW}Continuing installation (remember to install gum before using)...${NC}"
  echo ""
fi

# Detect shell type
SHELL_TYPE="bash"
SHELL_PATH=$(echo $SHELL)

if [[ "$SHELL_PATH" == *"zsh"* ]]; then
  SHELL_TYPE="zsh"
elif [[ "$SHELL_PATH" == *"bash"* ]]; then
  SHELL_TYPE="bash"
else
  echo -e "${YELLOW}🔍 Unable to auto-detect your shell type.${NC}"
  echo "Please select your shell:"
  echo "1) Bash"
  echo "2) Zsh"
  echo ""
  read -p "Enter selection (1-2): " shell_choice
  case $shell_choice in
  2) SHELL_TYPE="zsh" ;;
  *) SHELL_TYPE="bash" ;;
  esac
fi

echo -e "${BLUE}Detected shell: ${YELLOW}$SHELL_TYPE${NC}"
echo ""

# Create installation directory
echo -e "${BLUE}📁 Creating installation directory...${NC}"
mkdir -p ~/.git-scripts

# Create the main commit script
echo -e "${BLUE}📝 Creating commit wizard script...${NC}"
cat >~/.git-scripts/gum-commit.sh <<'EOF'
#!/bin/bash

# Gum Conventional Commit Tool
# Interactive commit message creator using conventional commit format
# Requires: gum (https://github.com/charmbracelet/gum)

set -e

# Colors for output
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Help function
show_help() {
    echo -e "${BLUE}Gum Conventional Commit Tool${NC}"
    echo ""
    echo "Creates standardized commit messages using interactive prompts."
    echo ""
    echo "Usage:"
    echo "  git commit [options]"
    echo ""
    echo "Options:"
    echo "  -a, --all             Stage and commit all changes"
    echo "  -e, --edit            Open editor after creating message"
    echo "  -v, --verbose         Show diff in commit editor"
    echo "  -m, --message TEXT    Use TEXT as description (still prompts for type/scope)"
    echo "  --amend               Amend the previous commit"
    echo "  --no-wizard           Skip wizard and use standard git commit"
    echo "  -h, --help            Show this help message"
    echo ""
    echo "Examples:"
    echo "  git commit                    # Interactive wizard"
    echo "  git commit -m \"fix bug\"       # Wizard with predefined message"
    echo "  git commit --amend            # Amend with wizard"
    echo "  git commit --no-wizard -m \"text\" # Standard git commit"
    exit 0
}

# Parse command line arguments
skip_wizard=false
has_message=false
message_value=""
show_help_flag=false

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

if [ "$show_help_flag" = true ]; then
    show_help
fi

# Skip wizard if requested
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

# Verify gum is available
if ! command -v gum &> /dev/null; then
    echo -e "${RED}❌ Error: gum is not installed${NC}"
    echo ""
    echo "Install gum to use the commit wizard:"
    echo "  macOS: brew install gum"
    echo "  Other: https://github.com/charmbracelet/gum#installation"
    echo ""
    echo "Or use: git commit --no-wizard [options] to bypass the wizard"
    exit 1
fi

# Verify we're in a git repository
if ! git rev-parse --git-dir > /dev/null 2>&1; then
    echo -e "${RED}❌ Error: Not in a git repository${NC}"
    exit 1
fi

# Check for changes (unless amending)
is_amend=false
for arg in "$@"; do
    if [ "$arg" = "--amend" ]; then
        is_amend=true
        break
    fi
done

if [ "$is_amend" = false ] && git diff --cached --quiet && git diff --quiet; then
    echo -e "${RED}❌ No changes to commit${NC}"
    echo "Stage some changes first with: git add <files>"
    exit 1
fi

# Welcome message
echo "🎯 Interactive Conventional Commit Wizard"
echo ""

# Initialize variables
type=""
scope=""
breaking_change=""
message=""

# Handle amend commits - try to extract previous values
if [ "$is_amend" = true ]; then
    last_commit=$(git log -1 --pretty=%B)
    
    # Parse conventional commit format
    if [[ $last_commit =~ ^([a-z]+)(\([a-zA-Z0-9_-]+\))?(!)?:\ (.*)$ ]]; then
        prev_type="${BASH_REMATCH[1]}"
        prev_scope="${BASH_REMATCH[2]}"
        prev_breaking="${BASH_REMATCH[3]}"
        prev_message="${BASH_REMATCH[4]}"
        
        # Clean up scope formatting
        prev_scope="${prev_scope#(}"
        prev_scope="${prev_scope%)}"
        
        echo -e "${BLUE}Previous commit information:${NC}"
        echo -e "  Type: ${YELLOW}$prev_type${NC}"
        [ -n "$prev_scope" ] && echo -e "  Scope: ${YELLOW}$prev_scope${NC}"
        [ -n "$prev_breaking" ] && echo -e "  Breaking: ${YELLOW}Yes${NC}"
        echo -e "  Message: ${YELLOW}$prev_message${NC}"
        echo ""
        
        if gum confirm "Reuse these values?"; then
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

# Step 1: Select commit type
if [ -z "$type" ]; then
    type=$(gum choose \
        "feat" "fix" "docs" "style" "refactor" "test" "chore" "perf" "ci" "build" "revert" \
        --header "📋 Select the type of change you're making:")
fi

echo -e "${GREEN}✓${NC} Type: ${YELLOW}$type${NC}"

# Step 2: Optional scope
if [ -z "$scope" ]; then
    echo ""
    scope=$(gum input \
        --placeholder "e.g., auth, api, ui (press Enter to skip)" \
        --prompt "🎯 Scope (optional): " \
        --value "$scope")
fi

if [ -n "$scope" ]; then
    echo -e "${GREEN}✓${NC} Scope: ${YELLOW}$scope${NC}"
fi

# Step 3: Breaking change check
if [ -z "$breaking_change" ]; then
    echo ""
    if gum confirm "💥 Is this a breaking change?"; then
        breaking_change="yes"
    fi
fi

if [ "$breaking_change" = "yes" ]; then
    echo -e "${GREEN}✓${NC} Breaking change: ${YELLOW}Yes${NC}"
fi

# Step 4: Commit message
if [ "$has_message" = true ] && [ -n "$message_value" ]; then
    message="$message_value"
    echo ""
    echo -e "${GREEN}✓${NC} Using provided message: ${YELLOW}$message${NC}"
elif [ -z "$message" ]; then
    echo ""
    message=$(gum input \
        --placeholder "Brief description of the change" \
        --prompt "💬 Description: " \
        --width 80)
fi

echo -e "${GREEN}✓${NC} Description: ${YELLOW}$message${NC}"

# Step 5: Optional extended description
echo ""
echo "📝 Extended description (optional):"
body=$(gum write \
    --placeholder "Optional detailed description (Ctrl+D when finished, or press Enter to skip)")

if [ -n "$body" ]; then
    echo -e "${GREEN}✓${NC} Extended description added"
fi

# Step 6: Optional issue references
echo ""
closes=""
if gum confirm "🔗 Does this close any issues or tickets?"; then
    closes=$(gum input \
        --placeholder "e.g., #123, fixes #456, closes #789" \
        --prompt "📎 Issue references: ")
fi

if [ -n "$closes" ]; then
    echo -e "${GREEN}✓${NC} Issues: ${YELLOW}$closes${NC}"
fi

# Build the complete commit message
commit_msg=""

# Main commit line
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

# Add extended description
if [ -n "$body" ]; then
    commit_msg="${commit_msg}

${body}"
fi

# Add breaking change details if needed
if [ "$breaking_change" = "yes" ] && [ -n "$body" ]; then
    echo ""
    echo "💥 Breaking change details:"
    breaking_details=$(gum write \
        --placeholder "Describe what breaks and how to migrate (Ctrl+D when finished)")
    
    if [ -n "$breaking_details" ]; then
        commit_msg="${commit_msg}

BREAKING CHANGE: ${breaking_details}"
    fi
fi

# Add issue references
if [ -n "$closes" ]; then
    commit_msg="${commit_msg}

Closes: ${closes}"
fi

# Preview the final commit message
echo ""
echo "📋 Commit Message Preview"
gum style \
    --border rounded \
    --border-foreground 212 \
    --padding "1 2" \
    --margin "1 0" \
    "$commit_msg"

# Final confirmation
echo ""
if ! gum confirm "🚀 Create this commit?"; then
    echo -e "${RED}❌ Commit cancelled${NC}"
    exit 1
fi

# Prepare git arguments (remove our custom flags)
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

# Auto-stage files if needed
if [ "$is_amend" = false ] && git diff --cached --quiet; then
    echo "📦 Staging all changes..."
    git add .
fi

# Check for edit flag
edit_message=false
for arg in "${new_args[@]}"; do
    if [ "$arg" = "-e" ] || [ "$arg" = "--edit" ]; then
        edit_message=true
        break
    fi
done

# Execute the commit
if [ "$edit_message" = true ]; then
    temp_file=$(mktemp)
    echo "$commit_msg" > "$temp_file"
    git commit -F "$temp_file" -e "${new_args[@]}"
    exit_code=$?
    rm -f "$temp_file"
else
    git commit -m "$commit_msg" "${new_args[@]}"
    exit_code=$?
fi

# Show result
if [ $exit_code -eq 0 ]; then
    echo ""
    echo -e "${GREEN}✅ Commit created successfully!${NC}"
    echo ""
    echo "📋 Summary:"
    git log -1 --oneline
else
    echo -e "${RED}❌ Commit failed with exit code $exit_code${NC}"
fi

exit $exit_code
EOF

# Make script executable
chmod +x ~/.git-scripts/gum-commit.sh

# Configure git alias
echo -e "${BLUE}🔧 Setting up git integration...${NC}"
git config --global alias.commit '!~/.git-scripts/gum-commit.sh'

# Determine shell configuration file
if [ "$SHELL_TYPE" = "zsh" ]; then
  SHELL_CONFIG_FILE=~/.zshrc
else
  SHELL_CONFIG_FILE=~/.bashrc
fi

echo -e "${BLUE}⚙️  Configuring shell integration in ${YELLOW}$SHELL_CONFIG_FILE${NC}"

# Add git wrapper function if it doesn't exist
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
  echo -e "${GREEN}✓ Shell integration added${NC}"
else
  echo -e "${YELLOW}⚠ Shell integration already exists${NC}"
fi

# Installation complete
echo ""
echo -e "${GREEN}🎉 Installation Complete!${NC}"
echo ""
echo -e "${BLUE}📖 What was installed:${NC}"
echo -e "  • Interactive commit wizard at ~/.git-scripts/gum-commit.sh"
echo -e "  • Git alias to use the wizard automatically"
echo -e "  • Shell function to intercept 'git commit' commands"
echo ""
echo -e "${BLUE}🚀 How to use:${NC}"
echo -e "  ${YELLOW}git commit${NC}                 - Start interactive wizard"
echo -e "  ${YELLOW}git commit -m \"message\"${NC}    - Use wizard with predefined message"
echo -e "  ${YELLOW}git commit --amend${NC}          - Amend commit with wizard"
echo -e "  ${YELLOW}git commit --no-wizard${NC}      - Skip wizard (standard git commit)"
echo ""
echo -e "${BLUE}📋 Commit types available:${NC}"
echo -e "  • ${YELLOW}feat${NC}     - New features"
echo -e "  • ${YELLOW}fix${NC}      - Bug fixes"
echo -e "  • ${YELLOW}docs${NC}     - Documentation changes"
echo -e "  • ${YELLOW}style${NC}    - Code style changes (formatting, etc.)"
echo -e "  • ${YELLOW}refactor${NC} - Code refactoring"
echo -e "  • ${YELLOW}test${NC}     - Adding or updating tests"
echo -e "  • ${YELLOW}chore${NC}    - Maintenance tasks"
echo -e "  • ${YELLOW}perf${NC}     - Performance improvements"
echo -e "  • ${YELLOW}ci${NC}       - CI/CD changes"
echo -e "  • ${YELLOW}build${NC}    - Build system changes"
echo -e "  • ${YELLOW}revert${NC}   - Reverting changes"
echo ""
echo -e "${BLUE}🔄 To activate in current shell:${NC}"
echo -e "  ${YELLOW}source $SHELL_CONFIG_FILE${NC}"
echo -e "  ${BLUE}(or restart your terminal)${NC}"

if ! command -v gum &>/dev/null; then
  echo ""
  echo -e "${YELLOW}⚠️  Don't forget to install gum:${NC}"
  echo -e "  ${BLUE}macOS:${NC}   brew install gum"
  echo -e "  ${BLUE}Other:${NC}   https://github.com/charmbracelet/gum#installation"
fi

echo ""
echo -e "${GREEN}Happy committing! 🚀${NC}"
