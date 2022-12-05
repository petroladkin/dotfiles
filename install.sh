#!/bin/bash

IS_OSX=1
IS_LINUX=0
IS_FEDORA_LINUX=0
IS_UBUNTU_LINUX=0
#TODO: add check OSX
if grep "^NAME=" /etc/os-release | grep -q "Fedora"; then
  # Fedora
  IS_OSX=0
  IS_LINUX=1
  IS_FEDORA_LINUX=1
elif grep "^NAME=" /etc/os-release | grep -q "Ubuntu"; then
  # Ubuntu
  IS_OSX=0
  IS_LINUX=1
  IS_UBUNTU_LINUX=1
else
  grep "^NAME=" /etc/os-release
  echo 'ERROR: unsupported OS'
  exit -1
fi

if [ $IS_OSX -eq 1 ]; then
  echo "It's OSX"
  echo 'ERROR: unsupported OS'
  exit -1
fi

SUDO=""
if command -v sudo &> /dev/null; then
  echo "'sudo' exist"
  SUDO="sudo"
fi

if [ $IS_FEDORA_LINUX -eq 1 ]; then
  echo ""
  echo "It's FEDORA"

  echo ""
  $SUDO dnf update && $SUDO dnf install git -y
fi

if [ $IS_UBUNTU_LINUX -eq 1 ]; then
  echo ""
  echo "It's UBUNTU"

  echo ""
  $SUDO apt-get update && $SUDO apt-get install -y git
fi

if [ -d "$HOME/.dotfiles" ]; then
  echo "~/.dotfiles directory exist"
  exit -1
fi

git clone https://github.com/petroladkin/dotfiles.git ~/.dotfiles

cd ~/.dotfiles
./setup.sh