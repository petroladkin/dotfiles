# create links for dotfiles

rm    ~/.vimrc
rm -R ~/.vim
rm    ~/.tmux.conf
rm    ~/.zshrc

rpwd="$(pwd)"

ln -s "$rpwd/vimrc"     ~/.vimrc 
ln -s "$rpwd/vim"       ~/.vim
ln -s "$rpwd/tmux.conf" ~/.tmux.conf
ln -s "$rpwd/zshrc"     ~/.zshrc

