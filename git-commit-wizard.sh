#!/bin/bash

# Git Commit Wizard
# A script to standardize git commit messages using conventional commit format

# Colors for better readability
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Function to display help
show_help() {
  echo -e "${BLUE}Git Commit Wizard${NC}"
  echo "A tool to create standardized commit messages"
  echo ""
  echo "Usage:"
  echo "  git commit [options]"
  echo ""
  echo "Common options (passed to git commit):"
  echo "  -a, --all             Commit all changed files"
  echo "  -e, --edit            Open editor for commit message (after wizard)"
  echo "  -v, --verbose         Show diff in commit message editor"
  echo "  -m, --message         Use the provided message after selecting type and scope"
  echo "  --amend               Amend previous commit"
  echo "  --no-wizard           Skip the wizard and use normal git commit"
  echo ""
  echo "All other git commit options are supported and passed through."
  exit 0
}

# Parse arguments to check for --help, --no-wizard, and -m/--message
skip_wizard=false
has_message=false
message_value=""

# Loop through all arguments
for ((i=1; i<=$#; i++)); do
  arg="${!i}"
  
  case "$arg" in
    --help|-h)
      show_help
      ;;
    --no-wizard)
      skip_wizard=true
      ;;
    -m|--message)
      has_message=true
      # Get the next argument as the message
      next=$((i+1))
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

# If --no-wizard was specified, just pass through to git commit
if [ "$skip_wizard" = true ]; then
  # Remove --no-wizard flag since git commit doesn't understand it
  args=()
  for arg in "$@"; do
    if [ "$arg" != "--no-wizard" ]; then
      args+=("$arg")
    fi
  done
  exec git commit "${args[@]}"
  exit $?
fi

# Check if this is an amend, if so we may want to extract the prefix from the existing commit
is_amend=false
for arg in "$@"; do
  if [ "$arg" = "--amend" ]; then
    is_amend=true
    break
  fi
done

# Default values
type=""
scope=""
breaking=""
message=""

# If this is an amend, try to extract the prefix from the existing commit
if [ "$is_amend" = true ]; then
  # Get the last commit message
  last_commit=$(git log -1 --pretty=%B)
  
  # Try to extract conventional commit parts
  if [[ $last_commit =~ ^([a-z]+)(\([a-zA-Z0-9_-]+\))?(!)?:\ (.*)$ ]]; then
    type="${BASH_REMATCH[1]}"
    scope="${BASH_REMATCH[2]}"
    breaking="${BASH_REMATCH[3]}"
    message="${BASH_REMATCH[4]}"
    
    # Clean up scope (remove parentheses)
    scope="${scope#(}"
    scope="${scope%)}"
    
    echo -e "${BLUE}Extracted from previous commit:${NC}"
    echo -e "Type: ${YELLOW}$type${NC}"
    [ -n "$scope" ] && echo -e "Scope: ${YELLOW}$scope${NC}"
    [ -n "$breaking" ] && echo -e "Breaking: ${YELLOW}Yes${NC}"
    echo -e "Message: ${YELLOW}$message${NC}"
    echo ""
    
    echo -e "${GREEN}Use these values? [Y/n]${NC}"
    read -r reuse_values
    
    if [[ ! $reuse_values =~ ^[Nn]$ ]]; then
      # Keep these values
      echo -e "${BLUE}Using extracted values from previous commit${NC}"
    else
      # Reset the values
      type=""
      scope=""
      breaking=""
      message=""
    fi
  fi
fi

# If we don't have values from a previous commit, run the wizard
if [ -z "$type" ]; then
  echo -e "${BLUE}=== Git Commit Wizard ===${NC}"
  echo "This wizard helps format your commit messages according to conventional commits."
  echo ""

  # Prompt for commit type
  echo -e "${GREEN}Select commit type:${NC}"
  echo "1) feat: A new feature"
  echo "2) fix: A bug fix"
  echo "3) docs: Documentation only changes"
  echo "4) style: Changes that do not affect the meaning of the code"
  echo "5) refactor: A code change that neither fixes a bug nor adds a feature"
  echo "6) perf: A code change that improves performance"
  echo "7) test: Adding missing tests or correcting existing tests"
  echo "8) build: Changes that affect the build system or external dependencies"
  echo "9) ci: Changes to CI configuration files and scripts"
  echo "10) chore: Other changes that don't modify src or test files"
  echo "11) revert: Reverts a previous commit"
  echo "12) custom: Enter a custom type"
  
  # Read user choice directly instead of using select
  echo -e "${GREEN}Enter selection (1-12):${NC}"
  read -r choice
  
  # Process the selection
  case $choice in
      1)
          type="feat"
          ;;
      2)
          type="fix"
          ;;
      3)
          type="docs"
          ;;
      4)
          type="style"
          ;;
      5)
          type="refactor"
          ;;
      6)
          type="perf"
          ;;
      7)
          type="test"
          ;;
      8)
          type="build"
          ;;
      9)
          type="ci"
          ;;
      10)
          type="chore"
          ;;
      11)
          type="revert"
          ;;
      12)
          echo -e "${GREEN}Enter custom type (without colon):${NC}"
          read -r type
          ;;
      *)
          echo -e "${RED}Invalid selection. Defaulting to 'chore'.${NC}"
          type="chore"
          ;;
  esac
  
  echo -e "${BLUE}Selected type: ${YELLOW}$type${NC}"

  # Prompt for scope (optional)
  echo -e "${GREEN}Enter scope (optional, press enter to skip):${NC}"
  read -r scope

  # Prompt for breaking change indicator
  echo -e "${GREEN}Is this a BREAKING CHANGE? (y/N):${NC}"
  read -r breaking_change
  if [[ $breaking_change == "y" || $breaking_change == "Y" ]]; then
      breaking="!"
  else
      breaking=""
  fi

  # If -m flag was provided, use its value as the message
  if [ "$has_message" = true ] && [ -n "$message_value" ]; then
      message="$message_value"
      echo -e "${BLUE}Using provided commit message: ${YELLOW}$message${NC}"
  else
      # Prompt for commit message
      echo -e "${GREEN}Enter commit message:${NC}"
      read -r message
  fi
fi

# Format scope if provided
if [ -n "$scope" ]; then
    scope="($scope)"
fi

# Construct the commit message
commit_msg="$type$scope$breaking: $message"

# Display the final commit message
echo ""
echo -e "${BLUE}Final commit message:${NC}"
echo -e "${YELLOW}$commit_msg${NC}"
echo ""

# Check if -e or --edit flag was passed
edit_message=false
for arg in "$@"; do
  if [ "$arg" = "-e" ] || [ "$arg" = "--edit" ]; then
    edit_message=true
    break
  fi
done

# If edit flag wasn't passed and we don't have a message from -m, confirm commit
if [ "$edit_message" = false ] && [ "$has_message" = false ]; then
  echo -e "${GREEN}Proceed with this commit message? (Y/n/e):${NC}"
  echo -e "${BLUE}Y - Commit with this message${NC}"
  echo -e "${BLUE}n - Abort the commit${NC}"
  echo -e "${BLUE}e - Open editor to modify the message${NC}"
  read -r confirm
  if [[ $confirm == "n" || $confirm == "N" ]]; then
      echo -e "${RED}Commit canceled.${NC}"
      exit 1
  elif [[ $confirm == "e" || $confirm == "E" ]]; then
      edit_message=true
  fi
fi

# Build new git arguments without -m or --message flags
new_args=()
skip_next=false
for arg in "$@"; do
  if [ "$skip_next" = true ]; then
    skip_next=false
    continue
  fi
  
  if [[ "$arg" == "-m" || "$arg" == "--message" ]]; then
    skip_next=true
    continue
  fi
  
  if [[ "$arg" == -m=* || "$arg" == --message=* ]]; then
    continue
  fi
  
  if [ "$arg" != "--no-wizard" ]; then
    new_args+=("$arg")
  fi
done

# Debug output to verify message capturing (can be removed in production)
if [ "$has_message" = true ]; then
  echo -e "${BLUE}Using message from command line: '${YELLOW}${message_value}${BLUE}'${NC}"
fi

# Build the git commit command
if [ "$edit_message" = true ]; then
  # Create a temporary file for the commit message
  temp_file=$(mktemp)
  echo "$commit_msg" > "$temp_file"
  
  # Execute git commit with the file
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
  echo -e "${BLUE}Commit successful!${NC}"
else
  echo -e "${RED}Commit failed with exit code $exit_code${NC}"
fi

exit $exit_code
