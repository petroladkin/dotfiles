#
# What gets installed. Shared by setup.sh and update.sh.
#
# Package-manager names differ, so one list per manager. Tools with their own
# installers (neovim on apt, lazygit, fnm/node, claude, herdr, fresh, revdiff,
# uv, frogmouth, tdf) are handled by install_*/update_* functions in
# common/common.sh.
#

BREW_PACKAGES=(git curl tmux tig midnight-commander ripgrep fd fzf)
APT_PACKAGES=(git curl zsh tmux tig mc ripgrep fd-find fzf unzip build-essential)
DNF_PACKAGES=(git curl zsh tmux tig mc ripgrep fd-find fzf unzip gcc make)

# Also managed by the package manager where it provides them (upgraded by update.sh)
BREW_TOOLS=(neovim lazygit fnm tree-sitter-cli herdr fresh-editor revdiff uv tdf)
DNF_TOOLS=(neovim)
