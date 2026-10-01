#!/bin/bash
#
# Update an existing installation: pull the repo, re-run setup.sh (new
# symlinks, newly added tools), then upgrade everything already installed.
#

cd "$(dirname "$0")" || exit 1

. ./common/bash_colors.sh
. ./common/common.sh
. ./common/packages.sh

export PATH="$HOME/.local/bin:$PATH"
[ -d "$HOME/.local/share/fnm" ] && export PATH="$HOME/.local/share/fnm:$PATH"


info "update dotfiles repository"
if [ -n "$(git status --porcelain)" ]; then
  warn "repository has local changes, skipping git pull"
else
  git pull --ff-only || warn "git pull failed, continuing with the current checkout"
fi


info "re-run setup (symlinks, missing tools)"
DOTFILES_UPDATE=1 bash ./setup.sh


info "upgrade packages"
if [ $IS_OSX -eq 1 ]; then
  brew update
  # only formulae actually installed via brew (a tool may have come from its own installer)
  _upgrade=()
  for _f in "${BREW_PACKAGES[@]}" "${BREW_TOOLS[@]}"; do
    brew list --formula "$_f" &> /dev/null && _upgrade+=("$_f")
  done
  brew upgrade "${_upgrade[@]}"
elif [ $IS_FEDORA_LINUX -eq 1 ]; then
  ensure_root_or_sudo
  $SUDO dnf upgrade -y "${DNF_PACKAGES[@]}" "${DNF_TOOLS[@]}"
else
  ensure_root_or_sudo
  update_repos
  $SUDO apt-get install -y --only-upgrade "${APT_PACKAGES[@]}"
  apt_try_install lazygit   # no-op unless lazygit comes from apt on this release
fi

# Tools installed outside the package manager (Linux tarballs / user-local installers)
step "upgrade neovim"          update_neovim
step "upgrade lazygit"         update_lazygit
step "upgrade node"            update_fnm_node
step "upgrade tree-sitter-cli" update_tree_sitter_cli
step "upgrade claude"          update_claude_code
step "upgrade herdr"           update_herdr
step "upgrade fresh"           update_fresh
step "upgrade revdiff"         update_revdiff


info "update Oh My Zsh"
git -C "$HOME/.oh-my-zsh" pull --ff-only -q || warn "Oh My Zsh update failed"

info "update Powerlevel10k"
git -C "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" pull --ff-only -q || warn "Powerlevel10k update failed"


info "update neovim plugins (LazyVim sync, refreshes nvim/lazy-lock.json)"
nvim --headless "+Lazy! sync" +qa
if [ -n "$(git status --porcelain nvim/lazy-lock.json)" ]; then
  warn "nvim/lazy-lock.json changed: commit it so other machines get the same plugin versions"
fi


report_failed_steps
info "FINISH: restart your terminal or run: exec zsh"
