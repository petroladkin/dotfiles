#!/bin/bash

# Always run relative to the repo: common/* is sourced by relative path and
# $rpwd becomes the symlink target.
cd "$(dirname "$0")" || exit 1

. ./common/bash_colors.sh
. ./common/common.sh

rpwd="$(pwd)"


# =============================================================================
# What gets linked
# =============================================================================
CONFIG_FILES=(zshrc p10k.zsh tmux.conf tigrc)   # <repo>/X -> ~/.X
CONFIG_FOLDERS=(fonts)                          # <repo>/X -> ~/.X
XDG_CONFIG_DIRS=(nvim)                          # <repo>/X -> ~/.config/X

# What gets installed: common/packages.sh (shared with update.sh)
. ./common/packages.sh

# DOTFILES_UPDATE=1 (set by update.sh): keep ~/.custom.zshrc as is, no exec zsh at the end.
DOTFILES_UPDATE="${DOTFILES_UPDATE:-0}"


# =============================================================================
# Configs
# =============================================================================
PREV="$HOME/.previous_configs"

backup_if_real() {
  # move a real file/dir out of the way; leave symlinks alone (ln -sfn replaces them)
  local src="$1" dst="$2"
  if [ -e "$src" ] && [ ! -L "$src" ]; then
    debg "move '$src'  to  '$dst'"
    mkdir -p "$(dirname "$dst")"
    rm -rf "$dst"
    mv "$src" "$dst"
  fi
}

info "move previous configs to $PREV"
for f in "${CONFIG_FILES[@]}";    do backup_if_real "$HOME/.$f" "$PREV/.$f"; done
for d in "${CONFIG_FOLDERS[@]}";  do backup_if_real "$HOME/.$d" "$PREV/.$d"; done
for d in "${XDG_CONFIG_DIRS[@]}"; do backup_if_real "$HOME/.config/$d" "$PREV/.config/$d"; done

# -n: if the target is already a symlink to a directory, replace the link
# instead of creating a nested link inside it (which polluted the repo).
info "create symlinks to configs"
for f in "${CONFIG_FILES[@]}"; do
  debg "'$HOME/.$f'  ->  '$rpwd/$f'"
  ln -sfn "$rpwd/$f" "$HOME/.$f"
done
for d in "${CONFIG_FOLDERS[@]}"; do
  debg "'$HOME/.$d'  ->  '$rpwd/$d'"
  ln -sfn "$rpwd/$d" "$HOME/.$d"
done
mkdir -p "$HOME/.config"
for d in "${XDG_CONFIG_DIRS[@]}"; do
  debg "'$HOME/.config/$d'  ->  '$rpwd/$d'"
  ln -sfn "$rpwd/$d" "$HOME/.config/$d"
done


info "create .custom.zshrc"
if [ -f "$HOME/.custom.zshrc" ] && [ "$DOTFILES_UPDATE" -eq 1 ]; then
  info "keeping existing .custom.zshrc"
elif [ -f "$HOME/.custom.zshrc" ]; then
  echo
  info "'$HOME/.custom.zshrc' file exists, what to do:"
  info "  [1] - replace existing file"
  info "  [2] - move existing file to '$PREV'"
  info "  [c] - cancel"
  CUSTOM_ZSHRC=''
  question_regex CUSTOM_ZSHRC "Your choice?" "c" "^[12cC]$"

  if [[ $CUSTOM_ZSHRC = '1' ]]; then
    rm -f "$HOME/.custom.zshrc"
    touch "$HOME/.custom.zshrc"
  elif [[ $CUSTOM_ZSHRC = '2' ]]; then
    mkdir -p "$PREV"
    rm -f "$PREV/.custom.zshrc"
    mv "$HOME/.custom.zshrc" "$PREV/.custom.zshrc"
    touch "$HOME/.custom.zshrc"
  else
    info "Keeping existing .custom.zshrc"
  fi
else
  touch "$HOME/.custom.zshrc"
fi


# =============================================================================
# Packages
# =============================================================================
if [ $IS_OSX -eq 1 ]; then
  info "setting up macOS"
  ensure_brew_installed
  info "install packages"
  brew install "${BREW_PACKAGES[@]}"
else
  if [ $IS_WSL -eq 1 ]; then info "setting up Linux (WSL)"; else info "setting up Linux"; fi
  ensure_root_or_sudo
  update_repos
  info "install packages"
  if [ $IS_FEDORA_LINUX -eq 1 ]; then
    pkg_install "${DNF_PACKAGES[@]}"
  else
    pkg_install "${APT_PACKAGES[@]}"
  fi
fi

mkdir -p "$HOME/.local/bin"
export PATH="$HOME/.local/bin:$PATH"

# Debian/Ubuntu install fd as `fdfind`; LazyVim and fzf expect `fd`.
if [ $IS_APT_LINUX -eq 1 ] && ! command -v fd &> /dev/null && command -v fdfind &> /dev/null; then
  ln -sfn "$(command -v fdfind)" "$HOME/.local/bin/fd"
fi

step "install neovim"          install_neovim
step "install lazygit"         install_lazygit
step "install fnm + node"      install_fnm_node
step "install tree-sitter-cli" install_tree_sitter_cli
step "install claude"          install_claude_code
step "install herdr"           install_herdr
step "install fresh"           install_fresh
step "install revdiff"         install_revdiff


# =============================================================================
# Fonts (MesloLGS NF: Powerlevel10k + Nerd Font icons for LazyVim)
# =============================================================================
if [ $IS_OSX -eq 1 ]; then
  info "install fonts to ~/Library/Fonts/"
  mkdir -p "$HOME/Library/Fonts"
  cp "$rpwd/fonts/"*.ttf "$HOME/Library/Fonts/"
elif [ $IS_WSL -eq 1 ]; then
  warn "WSL: fonts must be installed on the Windows side."
  warn "     Open \\\\wsl\$\\$WSL_DISTRO_NAME$rpwd/fonts in Explorer, install the .ttf files,"
  warn "     then pick 'MesloLGS NF' in Windows Terminal profile settings."
else
  info "install fonts to ~/.local/share/fonts/"
  FONT_DIR="$HOME/.local/share/fonts"
  mkdir -p "$FONT_DIR"
  cp "$rpwd/fonts/"*.ttf "$FONT_DIR/"
  if ! command -v fc-cache &> /dev/null; then
    info "install 'fontconfig'"
    pkg_install fontconfig
  fi
  info "update font cache"
  fc-cache -f
fi


# =============================================================================
# Shell: Oh My Zsh + Powerlevel10k
# =============================================================================
info "install Oh My Zsh"
if [ ! -d "$HOME/.oh-my-zsh" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended --keep-zshrc \
    || FAILED_STEPS+=("install Oh My Zsh")
else
  info "Oh My Zsh already installed, skipping"
fi

info "install Powerlevel10k theme"
P10K_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
if [ ! -d "$P10K_DIR" ]; then
  git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$P10K_DIR" || FAILED_STEPS+=("install Powerlevel10k")
else
  info "Powerlevel10k already installed, skipping"
fi

step "set default shell" set_default_shell_zsh


# =============================================================================
# Neovim plugins (LazyVim): install the versions pinned in nvim/lazy-lock.json
# headlessly, so the first launch is instant. update.sh runs `Lazy! sync`.
# =============================================================================
step "install neovim plugins (LazyVim restore)" nvim --headless "+Lazy! restore" +qa


report_failed_steps
status=$?
if [ "$DOTFILES_UPDATE" -eq 1 ]; then
  exit $status
fi
info "FINISH"
if [ $IS_OSX -eq 1 ]; then
  info "Restart your terminal or run: exec zsh"
else
  info "Log out and back in so the default shell takes effect; for now: exec zsh"
fi
exec zsh
