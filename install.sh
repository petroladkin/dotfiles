# create links for dotfiles

# rm    ~/.vimrc
# rm -R ~/.vim
# rm    ~/.tmux.conf
rm    ~/.zshrc
rm    ~/.p10k.zsh

rpwd="$(pwd)"

# ln -s "$rpwd/vimrc"     ~/.vimrc 
# ln -s "$rpwd/vim"       ~/.vim
# ln -s "$rpwd/tmux.conf" ~/.tmux.conf
ln -s "$rpwd/zshrc"     ~/.zshrc
ln -s "$rpwd/p10k.zsh"  ~/.p10k.zsh

touch ~/.custom.zshrc

exec zsh
p10k configure
