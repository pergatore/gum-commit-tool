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

# Check if gum-commit.sh exists in the same directory as this installer
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_SCRIPT="$SCRIPT_DIR/gum-commit.sh"

if [ -f "$SOURCE_SCRIPT" ]; then
  # Copy the script from the same directory
  echo -e "${BLUE}📝 Installing gum-commit.sh from local directory...${NC}"
  cp "$SOURCE_SCRIPT" ~/.git-scripts/gum-commit.sh
  chmod +x ~/.git-scripts/gum-commit.sh
  echo -e "${GREEN}✓ Script copied successfully${NC}"
else
  echo -e "${RED}❌ Error: gum-commit.sh not found in the same directory as this installer${NC}"
  echo ""
  echo "Please ensure both files are in the same directory:"
  echo "  - gum-commit-installer.sh (this file)"
  echo "  - gum-commit.sh (the main script)"
  echo ""
  echo "You can download both files and place them together, then run this installer again."
  exit 1
fi

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
