#
# Common functionality for setup.sh
#

# shell output
debg() { clr_blue "$@"; }
info() { clr_green "$@"; }
warn() { clr_brown " *  $@" >&2; }
errr() { clr_red " ** $@" >&2; exit 1; }


# shell input
question_yn() {
  while true; do
    read -r -p "$1 " response
    if [[ "$response" = "" ]]; then
      response="$2"
    fi
    case $response in
      [yY]* ) return 0 ;;
      [nN]* ) return 1 ;;
      * ) echo "Please answer Yy or Nn." ;;
    esac
  done
}

# NOTE: plain calls, not `return $(...)`: command substitution would swallow
# the "Please answer" prompt into return's argument and break the status.
question_Yn() { question_yn "$1 [Y/n]" "Y"; }
question_yN() { question_yn "$1 [y/N]" "N"; }

question_regex() {
  local result=$1
  while true; do
    read -r -p "$2 [$3]: " response
    if [[ "$response" = "" ]]; then
      response="$3"
    fi
    if expr "$response" : "$4" >/dev/null; then
      eval $result="'$response'"
      break
    elif [[ "$response" = "_" ]]; then
      eval $result="''"
      break
    else
      echo "Bad format response."
    fi
  done
}


# OS detection using /etc/os-release ID field (more reliable than NAME)
# Keep in sync with tools/install.sh, which cannot source this file.
IS_OSX=0
IS_LINUX=0
IS_WSL=0
IS_FEDORA_LINUX=0
IS_UBUNTU_LINUX=0
IS_DEBIAN_LINUX=0
IS_POP_LINUX=0
IS_APT_LINUX=0  # covers Ubuntu, Debian, PopOS

if [[ -f "/etc/os-release" ]]; then
  IS_LINUX=1
  _os_id=$(grep "^ID=" /etc/os-release | cut -d= -f2 | tr -d '"')
  case "$_os_id" in
    fedora)
      IS_FEDORA_LINUX=1
      ;;
    ubuntu)
      IS_UBUNTU_LINUX=1
      IS_APT_LINUX=1
      ;;
    debian)
      IS_DEBIAN_LINUX=1
      IS_APT_LINUX=1
      ;;
    pop)
      IS_POP_LINUX=1
      IS_APT_LINUX=1
      ;;
    *)
      echo "WARNING: unrecognized Linux distribution (ID=$_os_id), attempting apt-based setup"
      IS_APT_LINUX=1
      ;;
  esac
  if [[ -n "${WSL_DISTRO_NAME:-}" ]] || grep -qi microsoft /proc/version 2>/dev/null; then
    IS_WSL=1
  fi
else
  IS_OSX=1
fi

ARCH="$(uname -m)"   # x86_64 | arm64 | aarch64

SUDO=""
if [ "$(id -u)" -ne 0 ] && command -v sudo &> /dev/null; then
  SUDO="sudo"
fi

# Linux: package installs need root. Debian without sudo (root password set
# at install time) is the common trap: apt-get would silently fail as user.
ensure_root_or_sudo() {
  if [ $IS_LINUX -eq 1 ] && [ "$(id -u)" -ne 0 ] && [ -z "$SUDO" ]; then
    errr "need root or sudo to install packages (Debian: apt-get install sudo && usermod -aG sudo $USER)"
  fi
}


ensure_brew_installed() {
  if ! command -v brew &> /dev/null; then
    info "installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add brew to PATH for Apple Silicon
    if [[ -f "/opt/homebrew/bin/brew" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    fi
  fi
}

update_repos() {
  if [ $IS_APT_LINUX -eq 1 ]; then
    info "update apt repositories"
    $SUDO apt-get update
  fi
}

pkg_install() {
  if [ $IS_FEDORA_LINUX -eq 1 ]; then
    $SUDO dnf install -y "$@"
  elif [ $IS_APT_LINUX -eq 1 ]; then
    $SUDO apt-get install -y "$@"
  elif [ $IS_OSX -eq 1 ]; then
    brew install "$@"
  fi
}

# `apt-get install` for a package that may not exist in this release.
apt_try_install() {
  [ $IS_APT_LINUX -eq 1 ] || return 1
  apt-cache show "$1" &> /dev/null || return 1
  $SUDO apt-get install -y "$1"
}

# `chsh` lives in util-linux-user on Fedora; guard rather than install blindly.
ensure_chsh() {
  if ! command -v chsh &> /dev/null && [ $IS_FEDORA_LINUX -eq 1 ]; then
    info "install 'util-linux-user' (provides chsh on Fedora)"
    pkg_install util-linux-user
  fi
}

set_default_shell_zsh() {
  local zsh_path
  zsh_path="$(command -v zsh)"
  if [ "$(basename "${SHELL:-}")" = "zsh" ]; then
    info "zsh is already the default shell, skipping"
    return 0
  fi
  ensure_chsh
  info "set zsh as default shell (may ask for your password)"
  # chsh needs the user's password; non-interactive runs (no tty) fail with
  # "PAM: Authentication failure", so fall back to sudo when it is available.
  chsh -s "$zsh_path" || $SUDO chsh -s "$zsh_path" "$USER" || warn "could not change the login shell to zsh"
}

# Track steps that failed so setup.sh can print a summary instead of exiting 0 silently.
FAILED_STEPS=()
step() {
  # usage: step "<label>" <command...>
  local label="$1"; shift
  info "$label"
  if ! "$@"; then
    FAILED_STEPS+=("$label")
    warn "step failed: $label"
  fi
}
report_failed_steps() {
  if [ ${#FAILED_STEPS[@]} -eq 0 ]; then
    info "all steps succeeded"
    return 0
  fi
  warn "FAILED STEPS (${#FAILED_STEPS[@]}):"
  for s in "${FAILED_STEPS[@]}"; do warn "  - $s"; done
  return 1
}


# ---------------------------------------------------------------------------
# Tool installers. Every one is idempotent: skips if the tool is on PATH.
# User-local installers put binaries in ~/.local/bin; zshrc adds it to PATH.
# ---------------------------------------------------------------------------

install_neovim() {
  if command -v nvim &> /dev/null; then
    info "neovim already installed ($(nvim --version | head -1)), skipping"
    return 0
  fi
  if [ $IS_OSX -eq 1 ]; then
    brew install neovim
  elif [ $IS_FEDORA_LINUX -eq 1 ]; then
    $SUDO dnf install -y neovim
  elif [ $IS_APT_LINUX -eq 1 ]; then
    # apt ships neovim too old for LazyVim (needs >= 0.11.2): use the
    # official pre-built archive, as INSTALL.md recommends.
    install_neovim_from_github
  fi
}

install_neovim_from_github() {
    local _arch
    case "$ARCH" in
      aarch64|arm64) _arch="arm64"  ;;
      *)             _arch="x86_64" ;;
    esac
    local _name="nvim-linux-${_arch}"
    local _tmpdir
    _tmpdir=$(mktemp -d)
    info "downloading ${_name}.tar.gz from GitHub releases"
    curl -fsSL "https://github.com/neovim/neovim/releases/latest/download/${_name}.tar.gz" \
      -o "$_tmpdir/nvim.tar.gz"
    $SUDO rm -rf "/opt/${_name}"
    $SUDO tar -C /opt -xzf "$_tmpdir/nvim.tar.gz"
    $SUDO ln -sfn "/opt/${_name}/bin/nvim" /usr/local/bin/nvim
    rm -rf "$_tmpdir"
}

install_lazygit() {
  if command -v lazygit &> /dev/null; then
    info "lazygit already installed, skipping"
    return 0
  fi
  if [ $IS_OSX -eq 1 ]; then
    brew install lazygit
  elif [ $IS_APT_LINUX -eq 1 ] && apt_try_install lazygit; then
    # In apt since Debian 13 / Ubuntu 26.04
    return 0
  else
    # Older apt releases and Fedora (lazygit is only in a COPR there):
    # GitHub release tarball into /usr/local/bin.
    info "lazygit not in the distro repos, downloading from GitHub releases"
    install_lazygit_from_github
  fi
}

# Resolve the latest release tag without the GitHub API (60 req/h unauthenticated):
# /releases/latest redirects to /releases/tag/<tag>.
github_latest_tag() {
  curl -fsSLI -o /dev/null -w '%{url_effective}' "https://github.com/$1/releases/latest" | sed 's#.*/tag/##'
}

install_lazygit_from_github() {
    local _version
    _version="$(github_latest_tag jesseduffield/lazygit | sed 's/^v//')"
    if [ -z "$_version" ]; then
      warn "could not resolve lazygit version, skipping"
      return 1
    fi
    local _arch
    case "$ARCH" in
      x86_64)  _arch="x86_64" ;;
      aarch64) _arch="arm64"  ;;
      armv7l)  _arch="armv6"  ;;
      *)       _arch="x86_64" ;;
    esac
    local _tmpdir
    _tmpdir=$(mktemp -d)
    curl -fsSL "https://github.com/jesseduffield/lazygit/releases/latest/download/lazygit_${_version}_Linux_${_arch}.tar.gz" \
      -o "$_tmpdir/lazygit.tar.gz"
    tar -xf "$_tmpdir/lazygit.tar.gz" -C "$_tmpdir" lazygit
    $SUDO /usr/bin/install "$_tmpdir/lazygit" /usr/local/bin/lazygit
    rm -rf "$_tmpdir"
}

# fnm (Node version manager) + current Node LTS. Needed by Mason in LazyVim
# for npm-based language servers (TypeScript, JSON, YAML, CSS, HTML, pyright).
install_fnm_node() {
  if ! command -v fnm &> /dev/null; then
    if [ $IS_OSX -eq 1 ]; then
      brew install fnm
    else
      # installer defaults to ~/.local/share/fnm; --skip-shell: zshrc handles it
      curl -fsSL https://fnm.vercel.app/install | bash -s -- --skip-shell
      export PATH="$HOME/.local/share/fnm:$PATH"
    fi
  else
    info "fnm already installed, skipping"
  fi
  eval "$(fnm env --shell bash)"
  if fnm ls | grep -q lts-latest; then
    info "Node LTS already installed via fnm, skipping"
  else
    info "install Node LTS via fnm"
    fnm install --lts
    fnm default lts-latest
  fi
}

install_claude_code() {
  if command -v claude &> /dev/null; then
    info "claude already installed, skipping"
    return 0
  fi
  # Native installer (recommended, auto-updates), same on macOS/Linux/WSL.
  curl -fsSL https://claude.ai/install.sh | bash
}

install_herdr() {
  if command -v herdr &> /dev/null; then
    info "herdr already installed, skipping"
    return 0
  fi
  if [ $IS_OSX -eq 1 ]; then
    brew install herdr
  else
    curl -fsSL https://herdr.dev/install.sh | sh
  fi
}

install_fresh() {
  if command -v fresh &> /dev/null; then
    info "fresh already installed, skipping"
    return 0
  fi
  if [ $IS_OSX -eq 1 ]; then
    brew install fresh-editor
  else
    curl -fsSL https://raw.githubusercontent.com/sinelaw/fresh/refs/heads/master/scripts/install.sh | sh
  fi
}

# tree-sitter-cli: nvim-treesitter needs it to build parsers. Mason tries to
# install it itself during the headless sync and races; install it up front.
# npm has it too, but newer npm blocks its install script by default.
install_tree_sitter_cli() {
  if command -v tree-sitter &> /dev/null; then
    info "tree-sitter-cli already installed, skipping"
    return 0
  fi
  if [ $IS_OSX -eq 1 ]; then
    brew install tree-sitter-cli
  else
    install_tree_sitter_cli_from_github
  fi
}

install_tree_sitter_cli_from_github() {
  local _arch _tag
  case "$ARCH" in
    aarch64|arm64) _arch="arm64" ;;
    *)             _arch="x64"   ;;
  esac
  _tag="$(github_latest_tag tree-sitter/tree-sitter)"
  if [ -z "$_tag" ]; then
    warn "could not resolve tree-sitter version, skipping"
    return 1
  fi
  mkdir -p "$HOME/.local/bin"
  curl -fsSL "https://github.com/tree-sitter/tree-sitter/releases/download/${_tag}/tree-sitter-linux-${_arch}.gz" \
    | gunzip > "$HOME/.local/bin/tree-sitter"
  chmod +x "$HOME/.local/bin/tree-sitter"
}


# revdiff: TUI diff reviewer (github.com/umputun/revdiff). Third-party tap on
# macOS needs explicit trust in Homebrew 5; Linux gets the release tarball.
install_revdiff() {
  if command -v revdiff &> /dev/null; then
    info "revdiff already installed, skipping"
    return 0
  fi
  if [ $IS_OSX -eq 1 ]; then
    brew trust --formula umputun/apps/revdiff
    brew install umputun/apps/revdiff
  else
    install_revdiff_from_github
  fi
}

install_revdiff_from_github() {
  local _arch _version _tmpdir
  case "$ARCH" in
    aarch64|arm64) _arch="arm64" ;;
    *)             _arch="amd64" ;;
  esac
  _version="$(github_latest_tag umputun/revdiff | sed 's/^v//')"
  if [ -z "$_version" ]; then
    warn "could not resolve revdiff version, skipping"
    return 1
  fi
  _tmpdir=$(mktemp -d)
  curl -fsSL "https://github.com/umputun/revdiff/releases/download/v${_version}/revdiff_${_version}_linux_${_arch}.tar.gz" \
    -o "$_tmpdir/revdiff.tar.gz"
  tar -xzf "$_tmpdir/revdiff.tar.gz" -C "$_tmpdir" revdiff
  mkdir -p "$HOME/.local/bin"
  command install "$_tmpdir/revdiff" "$HOME/.local/bin/revdiff"
  rm -rf "$_tmpdir"
}


# uv: Python tool manager, used here to install Python CLIs (frogmouth) in
# isolated environments. brew on macOS, Astral's installer into ~/.local/bin
# on Linux (UV_NO_MODIFY_PATH: zshrc already puts ~/.local/bin on PATH).
install_uv() {
  if command -v uv &> /dev/null; then
    info "uv already installed, skipping"
    return 0
  fi
  if [ $IS_OSX -eq 1 ]; then
    brew install uv
  else
    curl -LsSf https://astral.sh/uv/install.sh | env UV_NO_MODIFY_PATH=1 sh
  fi
}

# frogmouth: Markdown browser for the terminal (github.com/Textualize/frogmouth).
# Not packaged anywhere useful, so it is a uv tool on every OS.
install_frogmouth() {
  if command -v frogmouth &> /dev/null; then
    info "frogmouth already installed, skipping"
    return 0
  fi
  command -v uv &> /dev/null || { warn "uv not found, skipping frogmouth"; return 1; }
  uv tool install frogmouth
}

# tdf: PDF viewer for the terminal (github.com/itsjunetime/tdf), draws real
# pages through the kitty graphics protocol. Homebrew only: the project ships
# no Linux binaries, and the `tdf` crate on crates.io is an unrelated project.
install_tdf() {
  if command -v tdf &> /dev/null; then
    info "tdf already installed, skipping"
    return 0
  fi
  if [ $IS_OSX -eq 1 ]; then
    brew install tdf
  else
    info "tdf has no Linux release builds, skipping"
  fi
}

# ---------------------------------------------------------------------------
# Updaters for tools that no package manager tracks (used by update.sh).
# Each one is a no-op when the tool came from brew/apt/dnf.
# ---------------------------------------------------------------------------

# true when the tool on PATH is a user-local / manual install, not a package
is_user_local() {
  case "$(command -v "$1" 2>/dev/null)" in
    "$HOME"/.local/bin/*|/usr/local/bin/*) return 0 ;;
    *) return 1 ;;
  esac
}

update_neovim() {
  # only the /opt tarball install (apt systems) is ours to update
  [ -L /usr/local/bin/nvim ] && [[ "$(readlink /usr/local/bin/nvim)" == /opt/nvim-linux-* ]] || return 0
  local _have _latest
  _have="$(nvim --version | head -1 | sed 's/^NVIM v//')"
  _latest="$(github_latest_tag neovim/neovim | sed 's/^v//')"
  if [ "$_have" = "$_latest" ]; then
    info "neovim $_have is current"
  else
    info "neovim $_have -> $_latest"
    install_neovim_from_github
  fi
}

update_lazygit() {
  [ $IS_LINUX -eq 1 ] && [ -x /usr/local/bin/lazygit ] || return 0
  local _have _latest
  # output: "commit=…, build date=…, version=0.65.1, os=…, git version=2.56.0"
  _have="$(lazygit --version | grep -o ', version=[^,]*' | sed 's/.*=//')"
  _latest="$(github_latest_tag jesseduffield/lazygit | sed 's/^v//')"
  if [ "$_have" = "$_latest" ]; then
    info "lazygit $_have is current"
  else
    info "lazygit $_have -> $_latest"
    install_lazygit_from_github
  fi
}

update_fnm_node() {
  command -v fnm &> /dev/null || return 0
  eval "$(fnm env --shell bash)"
  fnm install --lts
  fnm default lts-latest
}

update_tree_sitter_cli() {
  [ $IS_LINUX -eq 1 ] && [ -x "$HOME/.local/bin/tree-sitter" ] || return 0
  local _have _latest
  _have="$(tree-sitter --version | awk '{print $2}')"
  _latest="$(github_latest_tag tree-sitter/tree-sitter | sed 's/^v//')"
  if [ "$_have" = "$_latest" ]; then
    info "tree-sitter-cli $_have is current"
  else
    info "tree-sitter-cli $_have -> $_latest"
    install_tree_sitter_cli_from_github
  fi
}

update_revdiff() {
  [ $IS_LINUX -eq 1 ] && [ -x "$HOME/.local/bin/revdiff" ] || return 0
  local _have _latest
  # output: "version: v1.13.0-<commit>-<date>"
  _have="$(revdiff --version | sed -n 's/^version: v\([0-9.]*\).*/\1/p')"
  _latest="$(github_latest_tag umputun/revdiff | sed 's/^v//')"
  if [ "$_have" = "$_latest" ]; then
    info "revdiff $_have is current"
  else
    info "revdiff $_have -> $_latest"
    install_revdiff_from_github
  fi
}

update_claude_code() {
  command -v claude &> /dev/null || return 0
  if is_user_local claude; then
    claude update
  else
    info "claude is managed by the package manager, skipping"
  fi
}

update_herdr() {
  command -v herdr &> /dev/null || return 0
  if is_user_local herdr; then
    herdr update
  else
    info "herdr is managed by the package manager, skipping"
  fi
}

update_fresh() {
  command -v fresh &> /dev/null || return 0
  if is_user_local fresh; then
    # the installer is idempotent and always fetches the latest release
    curl -fsSL https://raw.githubusercontent.com/sinelaw/fresh/refs/heads/master/scripts/install.sh | sh
  else
    info "fresh is managed by the package manager, skipping"
  fi
}


update_uv() {
  command -v uv &> /dev/null || return 0
  if is_user_local uv; then
    uv self update
  else
    info "uv is managed by the package manager, skipping"
  fi
}

update_frogmouth() {
  command -v uv &> /dev/null && command -v frogmouth &> /dev/null || return 0
  uv tool upgrade frogmouth
}
