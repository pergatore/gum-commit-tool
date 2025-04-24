# Simple Git Commit Wizard

A command-line tool that standardizes your Git commit messages according to the [Conventional Commits](https://www.conventionalcommits.org/) specification. This makes your repository history more consistent and easier to navigate.

![](https://img.shields.io/badge/Bash-4.0%2B-green)
![](https://img.shields.io/badge/License-MIT-blue)

## What it does

Git Commit Wizard:

- Intercepts `git commit` commands
- Prompts you to select a commit type (feat, fix, docs, etc.)
- Optionally adds a scope and breaking change indicator
- Formats your commit message according to conventional commits
- Can be bypassed when needed

## Features

- 🔄 Seamlessly replaces the standard Git commit flow
- 📋 Interactive menu for selecting commit types
- 🔍 Optional scope and breaking change support
- 📝 Editor integration (can open your editor after generation)
- ♻️ Smart handling of `--amend` by extracting format from previous commit
- 🚫 Bypass option with `--no-wizard` for when you need standard Git behavior

## Installation

### Bash Users

```bash
# Create the installation script
curl -o install-git-wizard.sh https://raw.githubusercontent.com/pergatore/git-commit-wizard/main/install-git-wizard.sh

# Make it executable
chmod +x install-git-wizard.sh

# Run the installer
./install-git-wizard.sh

# Apply changes to current session
source ~/.bashrc
```

### Zsh Users

```bash
# Create the installation script
curl -o install-git-wizard.sh https://raw.githubusercontent.com/pergatore/git-commit-wizard/main/install-git-wizard-zsh.sh

# Make it executable
chmod +x install-git-wizard.sh

# Run the installer
./install-git-wizard.sh

# Apply changes to current session
source ~/.zshrc
```

### Manual Installation

If you prefer to install manually:

1. Download the script from this repository
2. Place it in `~/.git-scripts/git-commit-wizard.sh`
3. Make it executable: `chmod +x ~/.git-scripts/git-commit-wizard.sh`
4. Add a Git alias: `git config --global alias.commit '!~/.git-scripts/git-commit-wizard.sh'`
5. Add to your shell config (`~/.bashrc` or `~/.zshrc`):
   ```bash
   # Git commit wrapper function
   git() {
     if [[ $1 == "commit" ]]; then
       shift 1
       command ~/.git-scripts/git-commit-wizard.sh "$@"
     else
       command git "$@"
     fi
   }
   ```

## Usage

### Basic Usage

Simply use Git normally. The wizard will be invoked whenever you run `git commit`:

```bash
git commit
```

The wizard will guide you through selecting:
1. Commit type (feat, fix, docs, etc.)
2. Scope (optional)
3. Breaking change indicator (optional)
4. Commit message

### Opening Editor

If you want to further edit the commit message in your preferred editor:

```bash
git commit -e
```

Or, during the wizard prompt, select 'e' when asked to proceed.

### Bypassing the Wizard

To bypass the wizard and use standard Git behavior:

```bash
git commit --no-wizard
```

### Amending Commits

When amending a commit:

```bash
git commit --amend
```

The wizard will extract the type, scope, and breaking change indicators from the previous commit message, allowing you to maintain consistency.

## Commit Types

| Type | Description |
|------|-------------|
| feat | A new feature |
| fix | A bug fix |
| docs | Documentation only changes |
| style | Changes that do not affect the meaning of the code |
| refactor | A code change that neither fixes a bug nor adds a feature |
| perf | A code change that improves performance |
| test | Adding missing tests or correcting existing tests |
| build | Changes that affect the build system or external dependencies |
| ci | Changes to CI configuration files and scripts |
| chore | Other changes that don't modify src or test files |
| revert | Reverts a previous commit |

## Uninstallation

```bash
# Remove git alias
git config --global --unset alias.commit

# Remove function from shell config
# Edit ~/.bashrc or ~/.zshrc and remove the git() function

# Remove the script
rm ~/.git-scripts/git-commit-wizard.sh
```

## License

MIT License
