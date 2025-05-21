#!/usr/bin/env bash
set -euo pipefail

# If not running as root, re-exec under sudo so we can write both user and root configs
if [[ $EUID -ne 0 ]]; then
  echo "Need root privileges to install for both users; re-running via sudo..."
  exec sudo bash "$0" "$@"
fi

# Determine original (non-root) user and home directory
ORIGINAL_USER="${SUDO_USER:-$USER}"
ORIGINAL_HOME="$(eval echo "~$ORIGINAL_USER")"

# Directory of this script (expects .zshrc next to it)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
if [[ ! -f "$SCRIPT_DIR/.zshrc" ]]; then
  echo "ERROR: .zshrc not found in ${SCRIPT_DIR}" >&2
  exit 1
fi

echo
echo "1) Installing dependencies…"
if command -v apt-get &>/dev/null; then
  apt-get update
  apt-get install -y zsh git curl direnv \
    zsh-syntax-highlighting zsh-autosuggestions
elif command -v yum &>/dev/null; then
  yum install -y zsh git curl direnv
  # On RHEL/CentOS, plugins may need manual cloning below
else
  echo "Unknown package manager; please install zsh, git, curl, direnv," \
       "zsh-syntax-highlighting & zsh-autosuggestions yourself." >&2
fi

echo
echo "2) Installing Oh-My-Zsh for user $ORIGINAL_USER (if missing)…"
if [[ ! -d "$ORIGINAL_HOME/.oh-my-zsh" ]]; then
  su - "$ORIGINAL_USER" -c \
    "export RUNZSH=no && \
     sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" --unattended"
else
  echo "   -> Oh-My-Zsh already installed for $ORIGINAL_USER."
fi

# Prepare custom plugin directory for the user
OMZ_CUSTOM="$ORIGINAL_HOME/.oh-my-zsh/custom"
mkdir -p "$OMZ_CUSTOM/plugins"

echo
echo "3) Ensuring Oh-My-Zsh community plugins are present for $ORIGINAL_USER…"
if [[ ! -d "$OMZ_CUSTOM/plugins/zsh-autosuggestions" ]]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions \
    "$OMZ_CUSTOM/plugins/zsh-autosuggestions"
  chown -R "$ORIGINAL_USER":"$ORIGINAL_USER" "$OMZ_CUSTOM/plugins/zsh-autosuggestions"
fi

if [[ ! -d "$OMZ_CUSTOM/plugins/zsh-syntax-highlighting" ]]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting \
    "$OMZ_CUSTOM/plugins/zsh-syntax-highlighting"
  chown -R "$ORIGINAL_USER":"$ORIGINAL_USER" "$OMZ_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# ─── also install plugins for root’s Oh-My-Zsh ────────────────────────────────
ROOT_OMZ_CUSTOM="/root/.oh-my-zsh/custom"
mkdir -p "$ROOT_OMZ_CUSTOM/plugins"

for plugin in zsh-autosuggestions zsh-syntax-highlighting; do
  if [[ ! -d "$ROOT_OMZ_CUSTOM/plugins/$plugin" ]]; then
    git clone "https://github.com/zsh-users/$plugin" \
      "$ROOT_OMZ_CUSTOM/plugins/$plugin"
  fi
done

echo
echo "4) .zshrc locations will be:"
USER_ZSHRC="$ORIGINAL_HOME/.zshrc"
ROOT_ZSHRC="/root/.zshrc"
echo "   – your user : $USER_ZSHRC"
echo "   – root user : $ROOT_ZSHRC"

echo
read -p "Proceed to back up & overwrite both? [Y/n] " yn
yn=${yn:-Y}
if [[ "$yn" =~ ^[Yy]$ ]]; then
  timestamp="$(date +%Y%m%d%H%M%S)"

  echo
  echo "Backing up and installing for $ORIGINAL_USER…"
  if [[ -f "$USER_ZSHRC" ]]; then
    cp "$USER_ZSHRC" "${USER_ZSHRC}.bak.${timestamp}"
    echo "  – backed up to ${USER_ZSHRC}.bak.${timestamp}"
  fi
  cp "$SCRIPT_DIR/.zshrc" "$USER_ZSHRC"
  chown "$ORIGINAL_USER":"$ORIGINAL_USER" "$USER_ZSHRC"
  echo "  – installed -> $USER_ZSHRC"

  echo
  echo "Backing up and installing for root…"
  if [[ -f "$ROOT_ZSHRC" ]]; then
    cp "$ROOT_ZSHRC" "${ROOT_ZSHRC}.bak.${timestamp}"
    echo "  – backed up to ${ROOT_ZSHRC}.bak.${timestamp}"
  fi
  cp "$SCRIPT_DIR/.zshrc" "$ROOT_ZSHRC"
  echo "  – installed -> $ROOT_ZSHRC"

  echo
  echo "Done! Open a new terminal or run 'exec zsh' to start using your new settings."
else
  echo "Aborted by user. No changes made."
fi
