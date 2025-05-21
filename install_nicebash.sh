#!/usr/bin/env bash
set -euo pipefail

# 1) Elevate to root if needed so we can write /root/.zshrc
if [[ $EUID -ne 0 ]]; then
  echo "Re-running as root to install for both users…"
  exec sudo bash "$0" "$@"
fi

# 2) Detect original (non-root) user & home
ORIGINAL_USER="${SUDO_USER:-$USER}"
ORIGINAL_HOME="$(eval echo "~$ORIGINAL_USER")"

# 3) Locate script dir (expects .zshrc next to it)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
if [[ ! -f "$SCRIPT_DIR/.zshrc" ]]; then
  echo "ERROR: .zshrc not found in $SCRIPT_DIR" >&2
  exit 1
fi

echo
echo "=== Installing system dependencies ==="
if command -v apt-get &>/dev/null; then
  apt-get update
  apt-get install -y \
    zsh git curl direnv fzf \
    zsh-syntax-highlighting zsh-autosuggestions
elif command -v yum &>/dev/null; then
  yum install -y \
    zsh git curl direnv fzf
  # plugins will be cloned manually below
else
  echo "⚠️  Unknown package manager – please install: zsh, git, curl, direnv, fzf," \
       "zsh-syntax-highlighting, zsh-autosuggestions yourself." >&2
fi

echo
echo "=== Installing Oh-My-Zsh for $ORIGINAL_USER (if missing) ==="
if [[ ! -d "$ORIGINAL_HOME/.oh-my-zsh" ]]; then
  su - "$ORIGINAL_USER" -c \
    "export RUNZSH=no && \
     sh -c \"\$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)\" --unattended"
else
  echo "→ Already have Oh-My-Zsh at $ORIGINAL_HOME/.oh-my-zsh"
fi

echo
echo "=== Installing Oh-My-Zsh for root (if missing) ==="
if [[ ! -d "/root/.oh-my-zsh" ]]; then
  RUNZSH=no CHSH=no KEEP_ZSHRC=yes \
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
else
  echo "→ Already have Oh-My-Zsh at /root/.oh-my-zsh"
fi

# 4) Prepare custom plugin dirs
USER_OMZ_CUSTOM="$ORIGINAL_HOME/.oh-my-zsh/custom"
ROOT_OMZ_CUSTOM="/root/.oh-my-zsh/custom"
mkdir -p "$USER_OMZ_CUSTOM/plugins" "$ROOT_OMZ_CUSTOM/plugins"

echo
echo "=== Cloning community plugins for $ORIGINAL_USER ==="
for plugin_repo in \
  https://github.com/zsh-users/zsh-autosuggestions \
  https://github.com/zsh-users/zsh-syntax-highlighting \
  https://github.com/Aloxaf/fzf-tab
do
  name="$(basename "$plugin_repo")"
  dest="$USER_OMZ_CUSTOM/plugins/$name"
  if [[ ! -d "$dest" ]]; then
    git clone "$plugin_repo" "$dest"
    chown -R "$ORIGINAL_USER":"$ORIGINAL_USER" "$dest"
    echo "→ Cloned $name"
  fi
done

echo
echo "=== Cloning community plugins for root ==="
for plugin_repo in \
  https://github.com/zsh-users/zsh-autosuggestions \
  https://github.com/zsh-users/zsh-syntax-highlighting \
  https://github.com/Aloxaf/fzf-tab
do
  name="$(basename "$plugin_repo")"
  dest="$ROOT_OMZ_CUSTOM/plugins/$name"
  if [[ ! -d "$dest" ]]; then
    git clone "$plugin_repo" "$dest"
    echo "→ Cloned $name for root"
  fi
done

echo
echo "=== .zshrc locations ==="
USER_ZSHRC="$ORIGINAL_HOME/.zshrc"
ROOT_ZSHRC="/root/.zshrc"
echo " • User .zshrc: $USER_ZSHRC"
echo " • Root .zshrc: $ROOT_ZSHRC"

read -p "Proceed to back up & overwrite both files? [Y/n] " yn
yn=${yn:-Y}
if [[ ! "$yn" =~ ^[Yy] ]]; then
  echo "Aborting. No changes made."
  exit 0
fi

timestamp="$(date +%Y%m%d%H%M%S)"

echo
echo "→ Backing up & installing for $ORIGINAL_USER"
if [[ -f "$USER_ZSHRC" ]]; then
  cp "$USER_ZSHRC" "${USER_ZSHRC}.bak.$timestamp"
  echo "   backed up to ${USER_ZSHRC}.bak.$timestamp"
fi
cp "$SCRIPT_DIR/.zshrc" "$USER_ZSHRC"
chown "$ORIGINAL_USER":"$ORIGINAL_USER" "$USER_ZSHRC"
echo "   installed → $USER_ZSHRC"

echo
echo "→ Backing up & installing for root"
if [[ -f "$ROOT_ZSHRC" ]]; then
  cp "$ROOT_ZSHRC" "${ROOT_ZSHRC}.bak.$timestamp"
  echo "   backed up to ${ROOT_ZSHRC}.bak.$timestamp"
fi
cp "$SCRIPT_DIR/.zshrc" "$ROOT_ZSHRC"
echo "   installed → $ROOT_ZSHRC"

echo
echo "=== Setting Zsh as default shell for $ORIGINAL_USER and root ==="

ZSH_PATH="$(command -v zsh)"

if [[ -x "$ZSH_PATH" ]]; then
  chsh -s "$ZSH_PATH" "$ORIGINAL_USER" && echo "→ $ORIGINAL_USER shell set to Zsh"
  chsh -s "$ZSH_PATH" root && echo "→ root shell set to Zsh"
else
  echo "❌ Could not find Zsh binary to set as default shell."
fi

echo
echo "✔ Installation complete! Open a new shell or run 'exec zsh'."
