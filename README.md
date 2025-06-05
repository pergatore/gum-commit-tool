# Gum Conventional Commit Tool

A modern, interactive command-line tool that creates beautiful, standardized Git commit messages following the [Conventional Commits](https://www.conventionalcommits.org/) specification. Built with [Gum](https://github.com/charmbracelet/gum) for a delightful user experience.

![](https://img.shields.io/badge/Bash-4.0%2B-green)
![](https://img.shields.io/badge/Gum-Required-purple)
![](https://img.shields.io/badge/License-MIT-blue)

## ✨ What it does

This tool transforms your commit workflow with:

- 🎯 **Interactive commit type selection** with numbered options
- 🎨 **Beautiful UI** powered by Gum's styling capabilities
- 📝 **Comprehensive commit building** with optional scope, breaking changes, and issue references
- 🔄 **Smart amend support** that reuses previous commit values
- 📋 **Live preview** of your commit message before creation
- 🚫 **Bypass option** when you need standard Git behavior

## 🚀 Features

- **Seamless Integration**: Intercepts `git commit` commands automatically
- **Interactive Selection**: Choose commit types by number (1-11) for speed
- **Rich Formatting**: Support for scopes, breaking changes, extended descriptions, and issue references
- **Beautiful Preview**: See exactly how your commit will look before confirming
- **Editor Support**: Open your editor for final tweaks with `-e` flag
- **Amend Intelligence**: Extracts and reuses values from previous commits when amending
- **Flexible Usage**: Works with all standard git commit flags

## 📦 Prerequisites

This tool requires [Gum](https://github.com/charmbracelet/gum) to be installed:

### Install Gum

**macOS:**
```bash
brew install gum
```

**Linux:**
```bash
# See https://github.com/charmbracelet/gum#installation for your distribution
```

**Other platforms:**
Visit the [Gum installation guide](https://github.com/charmbracelet/gum#installation)

## 🔧 Installation

### Quick Install

Download both files and run the installer:

```bash
# Download the files
curl -O https://raw.githubusercontent.com/pergatore/gum-commit-tool/main/gum-commit.sh
curl -O https://raw.githubusercontent.com/pergatore/gum-commit-tool/main/gum-commit-installer.sh

# Make the installer executable
chmod +x gum-commit-installer.sh

# Run the installer
./gum-commit-installer.sh

# Apply changes to your current session
source ~/.bashrc  # or ~/.zshrc for Zsh users
```

### Manual Installation

1. **Download the script:**
   ```bash
   mkdir -p ~/.git-scripts
   curl -o ~/.git-scripts/gum-commit.sh https://raw.githubusercontent.com/pergatore/gum-commit-tool/main/gum-commit.sh
   chmod +x ~/.git-scripts/gum-commit.sh
   ```

2. **Set up Git alias:**
   ```bash
   git config --global alias.commit '!~/.git-scripts/gum-commit.sh'
   ```

3. **Add shell integration:**
   Add to your `~/.bashrc` or `~/.zshrc`:
   ```bash
   # Gum commit wrapper function
   git() {
       if [[ $1 == "commit" ]]; then
           shift 1
           command ~/.git-scripts/gum-commit.sh "$@"
       else
           command git "$@"
       fi
   }
   ```

4. **Reload your shell:**
   ```bash
   source ~/.bashrc  # or ~/.zshrc
   ```

## 🎮 Usage

### Basic Commit

Simply use Git as normal - the interactive wizard starts automatically:

```bash
git commit
```

You'll be guided through:
1. **Type selection** (numbered 1-11 for quick selection)
2. **Optional scope** (e.g., auth, api, ui)
3. **Breaking change** confirmation
4. **Commit description**
5. **Extended description** (optional)
6. **Issue references** (optional)
7. **Beautiful preview** before confirming

### Quick Commit with Predefined Message

Provide a message and let the wizard handle type/scope:

```bash
git commit -m "add user authentication"
```

The wizard will still prompt for type and scope, but use your provided message.

### Editor Integration

Open your editor after the wizard creates the message:

```bash
git commit -e
```

### Amending Commits

When amending, the tool extracts values from your previous commit:

```bash
git commit --amend
```

You can choose to reuse the previous type, scope, and breaking change settings.

### Bypassing the Wizard

For standard Git commit behavior:

```bash
git commit --no-wizard -m "your message"
```

### All Standard Git Flags

The tool supports all standard git commit options:

```bash
git commit -a              # Stage and commit all changes
git commit -v              # Show diff in editor
git commit --amend         # Amend previous commit
git commit -e              # Open editor after wizard
git commit --no-wizard     # Skip wizard entirely
```

## 📋 Commit Types

| # | Type | Description |
|---|------|-------------|
| 1 | **feat** | A new feature |
| 2 | **fix** | A bug fix |
| 3 | **docs** | Documentation only changes |
| 4 | **style** | Changes that do not affect the meaning of the code |
| 5 | **refactor** | A code change that neither fixes a bug nor adds a feature |
| 6 | **test** | Adding missing tests or correcting existing tests |
| 7 | **chore** | Other changes that don't modify src or test files |
| 8 | **perf** | A code change that improves performance |
| 9 | **ci** | Changes to CI configuration files and scripts |
| 10 | **build** | Changes that affect the build system or external dependencies |
| 11 | **revert** | Reverts a previous commit |

## 🎨 Example Output

The tool creates properly formatted conventional commits:

```
feat(auth): add user login validation

Add comprehensive validation for user login including:
- Email format verification
- Password strength requirements
- Rate limiting for failed attempts

BREAKING CHANGE: Login endpoint now requires email instead of username

Closes: #123, #456
```

## 🛠️ Troubleshooting

### Gum Not Found

If you see "gum is not installed":
1. Install Gum following the [installation guide](https://github.com/charmbracelet/gum#installation)
2. Restart your terminal
3. Try the command again

### Function Not Working

If `git commit` doesn't trigger the wizard:
1. Reload your shell: `source ~/.bashrc` (or `~/.zshrc`)
2. Start a new terminal session
3. Check if the function exists: `type git`

### Bypassing Issues

If you need to temporarily disable the wizard:
```bash
git commit --no-wizard -m "emergency fix"
```

## 🗑️ Uninstallation

```bash
# Remove git alias
git config --global --unset alias.commit

# Remove the script
rm ~/.git-scripts/gum-commit.sh

# Remove function from shell config
# Edit ~/.bashrc or ~/.zshrc and remove the git() function
```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

MIT License - see LICENSE file for details.

## 🙏 Acknowledgments

- [Conventional Commits](https://www.conventionalcommits.org/) for the specification
- [Gum](https://github.com/charmbracelet/gum) by Charm for the beautiful CLI components
- The Git community for making version control awesome
