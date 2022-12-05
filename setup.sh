# create links for dotfiles

#TODO: auto install fonts
#TODO: check exist .custom.zshrc and show question to recreate the file
#TODO: add install zsh, oh-my-zsh, p10k, vim, tmux, tig  to the system

#TODO: [TEST] check system flags
#TODO: [TEST] auto install fonts

echo "SETUP dotfiles"

exit 0


IS_OSX=1
IS_LINUX=0
IS_FEDORA_LINUX=0
IS_UBUNTU_LINUX=0
if [[ $(which dnf) ]]; then
  # Fedora
  IS_LINUX=1
  IS_FEDORA_LINUX=1
elif [[ $(which apt) ]]; then
  # Ubuntu
  IS_LINUX=1
  IS_UBUNTU_LINUX=1
fi


# rm    ~/.vimrc
# rm -R ~/.vim
# rm    ~/.tmux.conf
#rm    ~/.zshrc
#rm    ~/.p10k.zsh
if [[ IS_LINUX == 1]]; then
  rm -rf ~/.fonts
fi

rpwd="$(pwd)"


# ln -s "$rpwd/vimrc"     ~/.vimrc
# ln -s "$rpwd/vim"       ~/.vim
# ln -s "$rpwd/tmux.conf" ~/.tmux.conf
#ln -s "$rpwd/zshrc"     ~/.zshrc
#ln -s "$rpwd/p10k.zsh"  ~/.p10k.zsh

if [[ IS_LINUX == 1]]; then
  ln -s "$rpwd/fonts" ~/.fonts
  fc-cache -f -v
fi

#touch ~/.custom.zshrc

# if Ubuntu or Fedora

#exec zsh
#p10k configure