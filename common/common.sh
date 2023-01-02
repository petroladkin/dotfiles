
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

IS_OSX=1
IS_LINUX=0
IS_FEDORA_LINUX=0
IS_UBUNTU_LINUX=0
if [[ -f "/etc/os-release" ]]; then
  # Linux
  if grep "^NAME=" /etc/os-release | grep -q "Fedora"; then
    # Fedora
    IS_OSX=0
    IS_LINUX=1
    IS_FEDORA_LINUX=1
  elif grep "^NAME=" /etc/os-release | grep -q "Ubuntu"; then
    # Ubuntu
    IS_OSX=0
    IS_LINUX=1
    IS_UBUNTU_LINUX=1
  else
    grep "^NAME=" /etc/os-release
    echo 'ERROR: unsupported OS'
    exit -1
  fi
fi

SUDO=""
if command -v sudo &> /dev/null; then
  SUDO="sudo"
fi


update_repos() {
  if [ $IS_UBUNTU_LINUX -eq 1 ]; then
    info "update apt repositories"
    $SUDO apt update
  fi
}

install() {
  if [ $IS_FEDORA_LINUX -eq 1 ]; then
    $SUDO dnf install -y $@
  fi
  if [ $IS_UBUNTU_LINUX -eq 1 ]; then
    $SUDO apt install -y $@
  fi
}
