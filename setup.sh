#!/bin/bash


. ./common/bash_colors.sh
. ./common/common.sh


rpwd="$(pwd)"


declare -a CONFIG_FILES=("vimrc" "tmux.conf" "zshrc" "p10k.zsh" "tigrc")
declare -a CONFIG_FOLDERS=("vim" "fonts")


info "move previous configs to .previous_configs"
for config_file in "${CONFIG_FILES[@]}"; do
  if [ -f "$HOME/.$config_file" ]; then
    debg "move '$HOME/.$config_file'  to  '$HOME/.previous_configs/.$config_file'"
    mkdir -p "$HOME/.previous_configs" &> /dev/null
    rm -f "$HOME/.previous_configs/.$config_file" &> /dev/null
    mv "$HOME/.$config_file" "$HOME/.previous_configs/.$config_file"
  fi
done
for config_folder in "${CONFIG_FOLDERS[@]}"; do
  if [ -d "$HOME/.$config_folder" ] && [ ! -L "$HOME/.$config_folder" ]; then
    debg "move '$HOME/.$config_folder'  to  '$HOME/.previous_configs/.$config_folder'"
    mkdir -p "$HOME/.previous_configs" &> /dev/null
    rm -rf "$HOME/.previous_configs/.$config_folder" &> /dev/null
    mv "$HOME/.$config_folder" "$HOME/.previous_configs/.$config_folder"
  fi
done


info "create symlinks to configs"
for config_file in "${CONFIG_FILES[@]}"; do
  debg "create symlink '$HOME/.$config_file'  ->  '$rpwd/$config_file'"
  ln -sf "$rpwd/$config_file" "$HOME/.$config_file"
done
for config_folder in "${CONFIG_FOLDERS[@]}"; do
  debg "create symlink '$HOME/.$config_folder'  ->  '$rpwd/$config_folder'"
  ln -sf "$rpwd/$config_folder" "$HOME/.$config_folder"
done


info "create .custom.zshrc"
if [ -f "$HOME/.custom.zshrc" ]; then
  echo
  info "'$HOME/.custom.zshrc' file exists, what to do:"
  info "  [1] - replace existing file"
  info "  [2] - move existing file to '$HOME/.previous_configs'"
  info "  [c] - cancel"
  CUSTOM_ZSHRC=''
  question_regex CUSTOM_ZSHRC "Your choice?" "12c" "^[12cC]$"

  if [[ $CUSTOM_ZSHRC = 'c' || $CUSTOM_ZSHRC = 'C' ]]; then
    info "Cancelled. Keeping existing .custom.zshrc"
  elif [[ $CUSTOM_ZSHRC = '1' ]]; then
    rm -f "$HOME/.custom.zshrc"
    touch "$HOME/.custom.zshrc"
  elif [[ $CUSTOM_ZSHRC = '2' ]]; then
    mkdir -p "$HOME/.previous_configs" &> /dev/null
    rm -f "$HOME/.previous_configs/.custom.zshrc" &> /dev/null
    mv "$HOME/.custom.zshrc" "$HOME/.previous_configs/.custom.zshrc"
    touch "$HOME/.custom.zshrc"
  fi
else
  touch "$HOME/.custom.zshrc"
fi


if [ "$IS_OSX" -eq 1 ]; then
  info "setting up macOS"

  ensure_brew_installed

  info "install packages"
  brew install vim tmux tig git curl

  info "install fonts to ~/Library/Fonts/"
  mkdir -p "$HOME/Library/Fonts"
  cp "$rpwd/fonts/"*.ttf "$HOME/Library/Fonts/"

  info "install Oh My Zsh"
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
  else
    info "Oh My Zsh already installed, skipping"
  fi

  info "install Powerlevel10k theme"
  P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [ ! -d "$P10K_DIR" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
  else
    info "Powerlevel10k already installed, skipping"
  fi

  info "install vim plugins"
  vim +PlugInstall +qall

  info "set zsh as default shell"
  chsh -s "$(which zsh)"

  info "FINISH"
  info "Please restart your terminal or run: exec zsh"
  exec zsh
fi


# Linux setup
update_repos

info "install fonts"
FONT_DIR="$HOME/.local/share/fonts"
mkdir -p "$FONT_DIR"
cp "$rpwd/fonts/"*.ttf "$FONT_DIR/"

if ! command -v fc-cache &> /dev/null; then
  info "install 'fontconfig'"
  install fontconfig
fi
info "update font cache"
fc-cache -f

info "install packages"
install vim tmux tig zsh curl git

if [ $IS_FEDORA_LINUX -eq 1 ]; then
  info "install 'util-linux-user' (required for chsh on Fedora)"
  install util-linux-user
fi

info "set zsh as default shell"
chsh -s "$(which zsh)"

info "install Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc
else
  info "Oh My Zsh already installed, skipping"
fi

info "install Powerlevel10k theme"
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR"
else
  info "Powerlevel10k already installed, skipping"
fi

info "install vim plugins"
vim +PlugInstall +qall


info "FINISH, need to reboot system"
if question_Yn "Reboot system now?"; then
  info "rebooting..."
  $SUDO reboot now
else
  info "run zsh"
  exec zsh
fi
