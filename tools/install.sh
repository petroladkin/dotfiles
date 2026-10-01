#!/bin/bash

# OS detection: keep in sync with common/common.sh (not available before clone)
IS_OSX=0
IS_FEDORA_LINUX=0
IS_APT_LINUX=0

if [[ -f "/etc/os-release" ]]; then
  _os_id=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
  case "$_os_id" in
    fedora)
      IS_FEDORA_LINUX=1
      ;;
    ubuntu|debian|pop)
      IS_APT_LINUX=1
      ;;
    *)
      echo "WARNING: unrecognized Linux distribution (ID=$_os_id), attempting apt-based setup"
      IS_APT_LINUX=1
      ;;
  esac
else
  IS_OSX=1
fi


SUDO=""
if [ "$(id -u)" -ne 0 ] && command -v sudo &> /dev/null; then
  SUDO="sudo"
fi
if [ $IS_OSX -eq 0 ] && [ "$(id -u)" -ne 0 ] && [ -z "$SUDO" ]; then
  echo "ERROR: need root or sudo (Debian: su -c 'apt-get install sudo && usermod -aG sudo $USER', then re-login)" >&2
  exit 1
fi


if [ $IS_FEDORA_LINUX -eq 1 ]; then
  $SUDO dnf install git -y
fi

if [ $IS_APT_LINUX -eq 1 ]; then
  $SUDO apt-get update && $SUDO apt-get install -y git
fi

if [ $IS_OSX -eq 1 ]; then
  if ! command -v brew &> /dev/null; then
    echo "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  fi
  brew install git
fi


if [ -d "$HOME/.dotfiles" ]; then
  echo "$HOME/.dotfiles directory already exists"
  exit 1
fi

git clone https://github.com/petroladkin/dotfiles.git ~/.dotfiles

cd ~/.dotfiles || exit 1
./setup.sh
