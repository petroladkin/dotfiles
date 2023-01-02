#!/bin/bash

IS_OSX=1
IS_FEDORA_LINUX=0
IS_UBUNTU_LINUX=0
if [[ -f "/etc/os-release" ]]; then
  # Linux
  if grep "^NAME=" /etc/os-release | grep -q "Fedora"; then
    # Fedora
    IS_OSX=0
    IS_FEDORA_LINUX=1
  elif grep "^NAME=" /etc/os-release | grep -q "Ubuntu"; then
    # Ubuntu
    IS_OSX=0
    IS_UBUNTU_LINUX=1
  else
    grep "^NAME=" /etc/os-release
    echo 'ERROR: unsupported OS'
    exit 1
  fi
fi


SUDO=""
if command -v sudo &> /dev/null; then
  SUDO="sudo"
fi

if [ $IS_FEDORA_LINUX -eq 1 ]; then
  echo ""
  $SUDO dnf install git -y
fi

if [ $IS_UBUNTU_LINUX -eq 1 ]; then
  echo ""
  $SUDO apt-get update && $SUDO apt-get install -y git
fi

if [ $IS_OSX -eq 1 ]; then
  echo ""
  brew install git
fi


if [ -d "$HOME/.dotfiles" ]; then
  echo "$HOME/.dotfiles directory exist"
  exit 1
fi

git clone https://github.com/petroladkin/dotfiles.git ~/.dotfiles

cd ~/.dotfiles || exit 1
./setup.sh
