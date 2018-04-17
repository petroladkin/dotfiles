tmux has-session -t dotfiles
if [ $? != 0 ]
then
  tmux new-session -s dotfiles -n vim -d
  tmux send-keys -t dotfiles 'vim .' C-m

  # tmux split-window -v -t dotfiles
  # tmux select-layout -t dotfiles main-horizontal
fi
tmux attach -t dotfiles

