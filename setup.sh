#!/bin/bash


. ./common/bash_colors.sh
. ./common/common.sh


rpwd="$(pwd)"


declare -a CONFIG_FILES=("vimrc" "tmux.conf" "zshrc" "p10k.zsh")
declare -a CONFIG_FOLDERS=("vim" "fonts")


info "move previous configs to .previous_configs"
for config_file in "${CONFIG_FILES[@]}"; do
  if [ -f "$HOME/.$config_file" ]; then
    debg "move '$HOME/.$config_file'  to  '$HOME/.previous_configs/.$config_file'"
    mkdir "$HOME/.previous_configs" &> /dev/null
    rm "$HOME/.previous_configs/.$config_file" &> /dev/null
    mv "$HOME/.$config_file" "$HOME/.previous_configs/.$config_file" &> /dev/null
  fi
done
for config_folder in "${CONFIG_FOLDERS[@]}"; do
  if [ -d "$HOME/.$config_folder" ]; then
    debg "move '$HOME/.$config_folder'  to  '$HOME/.previous_configs/.$config_folder'"
    mkdir "$HOME/.previous_configs" &> /dev/null
    rm -fR "$HOME/.previous_configs/.$config_folder" &> /dev/null
    mv "$HOME/.$config_folder" "$HOME/.previous_configs/.$config_folder" &> /dev/null
  fi
done


info "create symlinks to configs"
for config_file in "${CONFIG_FILES[@]}"; do
  debg "create symlink '$HOME/.$config_file'  to  '$rpwd/$config_file'"
  ln -s "$rpwd/$config_file" "$HOME/.$config_file" &> /dev/null
done
for config_folder in "${CONFIG_FOLDERS[@]}"; do
  debg "create symlink '$HOME/.$config_folder'  to  '$rpwd/$config_folder'"
  ln -s "$rpwd/$config_folder" "$HOME/.$config_folder" &> /dev/null
done


info "create .custom.zshrc"
if [ -f "$HOME/.custom.zshrc" ]; then
  echo
  info "'$HOME/.custom.zshrc' file exist, what to do:"
  info "  [1] - replace exist file"
  info "  [2] - move exist file to '$HOME/.previous_configs'"
  info "  [c] - cancel"
  CUSTOM_ZSHRC=''
  question_regex CUSTOM_ZSHRC "Do you select?" "12c" "^[12cC]$"

  if [[ $CUSTOM_ZSHRC = 'c' || $CUSTOM_ZSHRC = 'C' ]]; then
    exit 1
  fi

  if [[ $CUSTOM_ZSHRC = '1' ]]; then
    rm "$HOME/.custom.zshrc" &> /dev/null
  elif [[ $CUSTOM_ZSHRC = '2' ]]; then
    mkdir "$HOME/.previous_configs" &> /dev/null
    rm "$HOME/.previous_configs/.custom.zshrc" &> /dev/null
    mv "$HOME/.custom.zshrc" "$HOME/.previous_configs/.custom.zshrc" &> /dev/null
  fi
fi

touch "$HOME/.custom.zshrc"


if [ "$IS_OSX" -eq 1 ]; then
  info "TODO: add install tools in OSX"
  exit 0
fi


update_repos

if ! command -v fc-cache &> /dev/null; then
  info "install 'fontconfig'"
  install fontconfig
fi

if [ "$IS_LINUX" -eq 1 ]; then
  info "update font cache"
  fc-cache -f -v &> /dev/null
fi


info "install 'vim tmux tig zsh curl git'"
install vim tmux tig zsh curl git

if [ $IS_FEDORA_LINUX -eq 1 ]; then
  info "install 'util-linux-user'"
  install util-linux-user
fi


info 'setup zsh as default shell'
chsh -s $(which zsh)


info "install 'ohmyzsh'"
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc

info "install 'p10k'"
git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"


info "FINISH, need to reboot system"
if question_Yn "Do reboot system now?"; then
  info "rebooting..."
  $SUDO reboot now
else
  info "run zsh"
  exec zsh
fi
