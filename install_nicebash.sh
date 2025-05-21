#!/usr/bin/env bash
set -euo pipefail

# if not root, re-invoke via sudo so we can write /root/.zshrc
if [[ $EUID -ne 0 ]]; then
  echo "Need root to write /root/.zshrc; re-running via sudo..."
  exec sudo bash "$0" "$@"
fi

# figure out the original (non-root) user & home
ORIGINAL_USER="${SUDO_USER:-$USER}"
ORIGINAL_HOME="$(eval echo "~$ORIGINAL_USER")"

# location of this script (and of your “final” .zshrc)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 && pwd)"
if [[ ! -f "$SCRIPT_DIR/.zshrc" ]]; then
  echo "ERROR: can't find .zshrc in ${SCRIPT_DIR}" >&2
  exit 1
fi

echo
echo "1) Installing dependencies…"
if command -v apt-get &>/dev/null; then
  apt-get update
  apt-get install -y zsh git curl direnv zsh-syntax-highlighting zsh-autosuggestions
elif command -v yum &>/dev/null; then
  yum install -y zsh git curl direnv
  # on RHEL/CentOS you may need to clone plugins manually below
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
  echo "   -> already installed."
fi

# ensure plugin dirs exist for manual cloning if needed
OMZ_CUSTOM="${ORIGINAL_HOME}/.oh-my-zsh/custom"
mkdir -p "$OMZ_CUSTOM/plugins"

echo
echo "3) Ensuring community plugins are present…"
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

  echo "Backing up and copying for $ORIGINAL_USER…"
  if [[ -f "$USER_ZSHRC" ]]; then
    cp "$USER_ZSHRC" "${USER_ZSHRC}.bak.${timestamp}"
    echo "  backed up to ${USER_ZSHRC}.bak.${timestamp}"
  fi
  cp "$SCRIPT_DIR/.zshrc" "$USER_ZSHRC"
  chown "$ORIGINAL_USER":"$ORIGINAL_USER" "$USER_ZSHRC"
  echo "  installed -> $USER_ZSHRC"

  echo "Backing up and copying for root…"
  if [[ -f "$ROOT_ZSHRC" ]]; then
    cp "$ROOT_ZSHRC" "${ROOT_ZSHRC}.bak.${timestamp}"
    echo "  backed up to ${ROOT_ZSHRC}.bak.${timestamp}"
  fi
  cp "$SCRIPT_DIR/.zshrc" "$ROOT_ZSHRC"
  echo "  installed -> $ROOT_ZSHRC"

  echo
  echo "Done! Open a **new** terminal or run 'exec zsh' to start using your new prompt."
else
  echo "Aborted by user."
fi
