
#
# Common functionality
#

# shell output
debg() { clr_blue "$@"; }
info() { clr_green "$@"; }
warn() { clr_brown " *  $@" >&2; }
errr() { clr_red " ** $@" >&2; exit 1; }


# shell input
question_yn() {
  local result=false
  while true; do
    read -r -p "$1 " response
    if [[ "$response" = "" ]]; then
      response="$2"
    fi
    case $response in
      [yY]* )
          result=0
          break
          ;;

      [nN]* )
          result=1
          break
          ;;

      * ) echo "Please answer Yy or Nn.";;
    esac
  done
  return $result
}

question_Yn() {
  return $(question_yn "$1 [Y/n]" "Y")
}

question_yN() {
  return $(question_yn "$1 [y/N]" "N")
}

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
IS_OSX=0
IS_LINUX=0
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
else
  IS_OSX=1
fi

SUDO=""
if command -v sudo &> /dev/null; then
  SUDO="sudo"
fi


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

install() {
  if [ $IS_FEDORA_LINUX -eq 1 ]; then
    $SUDO dnf install -y "$@"
  elif [ $IS_APT_LINUX -eq 1 ]; then
    $SUDO apt-get install -y "$@"
  elif [ $IS_OSX -eq 1 ]; then
    brew install "$@"
  fi
}
