#!/bin/bash
set -euo pipefail

BLUE="\033[0;34m"
NC="\033[0m"

LOCAL_BIN="${HOME}/.local/bin"

info() {
  echo -e "${BLUE}[INFO]${NC} ${1}"
}

append() {
  grep -qF "$1" "$2" || echo "$1" | tee --append "$2"
}

install() {
  sudo apt update -qq
  sudo apt install -qqy --no-install-recommends "${@}"
}

uninstall_packages() {
  info "Uninstalling Packages"

  sudo apt autoremove --purge -qqy firefox popularity-contest snapd
}

setup_environment() {
  info "Setting up Environment"

  echo "${USER} ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/${USER}"
  mkdir -p "${LOCAL_BIN}"
  append "export PATH=\"\${PATH}:${HOME}/.local/bin\"" "${HOME}/.bashrc"
  install bash-completion curl git tar unzip
}

install_fonts() {
  info "Installing Fonts"

  curl -fsSL "https://fonts.google.com/download?family=Roboto" -o temp.zip
  sudo mkdir -p /usr/share/fonts/truetype/Roboto
  sudo unzip -o -q -d /usr/share/fonts/truetype/Roboto temp.zip "*.ttf"
  rm temp.zip

  curl -fsSL "https://fonts.google.com/download?family=Roboto%20Mono" -o temp.zip
  sudo mkdir -p /usr/share/fonts/truetype/RobotoMono
  sudo unzip -o -j -q -d /usr/share/fonts/truetype/RobotoMono temp.zip "*.ttf"
  rm temp.zip
}

install_chrome() {
  info "Installing Chrome"

  curl -fsSL "https://dl.google.com/linux/linux_signing_key.pub" | sudo apt-key add -
  echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb stable main" | sudo tee /etc/apt/sources.list.d/google-chrome.list
  install google-chrome-stable
}

install_docker() {
  info "Installing Docker"

  curl -fsSL "https://download.docker.com/linux/ubuntu/gpg" | sudo apt-key add -
  echo "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list
  install docker-ce docker-ce-cli containerd.io

  sudo usermod -aG docker "${USER}"
  sudo systemctl enable docker
}

install_go() {
  info "Installing Go"

  local version
  version=$(git ls-remote --tags --sort="v:refname" https://github.com/golang/go.git "go*" | grep -Eo "go[\.0-9]+$" | tail -1)
  curl -fsSL "https://golang.org/dl/${version}.linux-amd64.tar.gz" -o temp.tar.gz
  sudo tar -xf temp.tar.gz -C /usr/local
  rm temp.tar.gz
  append "export PATH=\"\${PATH}:/usr/local/go/bin\"" "${HOME}/.bashrc"
}

install_node() {
  info "Installing Node"

  local version
  version=$(curl -fsSL "https://api.github.com/repos/nvm-sh/nvm/releases/latest" | grep -Po '"tag_name": "v\K.*?(?=")')
  curl -fsSL "https://raw.githubusercontent.com/nvm-sh/nvm/v${version}/install.sh" | bash
  # shellcheck disable=SC1090
  source "${HOME}/.nvm/nvm.sh" && nvm install --lts
  npm i -g eslint prettier
}

install_terraform() {
  info "Installing Terraform"

  local version
  version=$(curl -fsSL "https://api.github.com/repos/hashicorp/terraform/releases/latest" | grep -Po '"tag_name": "v\K.*?(?=")')
  curl -fsSL "https://releases.hashicorp.com/terraform/${version}/terraform_${version}_linux_amd64.zip" -o temp.zip
  unzip -o -q -d "${LOCAL_BIN}" temp.zip
  rm temp.zip
}

install_vscode() {
  info "Installing Visual Studio Code"

  curl -fsSL "https://packages.microsoft.com/keys/microsoft.asc" | sudo apt-key add -
  echo "deb [arch=amd64] https://packages.microsoft.com/repos/vscode stable main" | sudo tee /etc/apt/sources.list.d/vscode.list
  install code

  local install
  install=(
    christian-kohler.path-intellisense
    dbaeumer.vscode-eslint
    esbenp.prettier-vscode
    golang.Go
    HashiCorp.terraform
    ms-azuretools.vscode-docker
    PKief.material-icon-theme
  )
  for extension in "${install[@]}"; do
      code --install-extension "${extension}"
  done

  tee "${HOME}/.config/Code/User/settings.json" <<EOT
  {
    "editor.defaultFormatter": "esbenp.prettier-vscode",
    "editor.formatOnSave": true,
    "editor.formatOnPaste": true,
    "editor.tabSize": 2,
    "editor.wordWrapColumn": 120,
    "explorer.confirmDelete": false,
    "files.autoSave": "onFocusChange",
    "javascript.format.semicolons": "insert",
    "javascript.preferences.quoteStyle": "double",
    "telemetry.enableCrashReporter": false,
    "telemetry.enableTelemetry": false,
    "workbench.editor.closeOnFileDelete": true,
    "workbench.iconTheme": "material-icon-theme",
    "material-icon-theme.activeIconPack": "none",
    "material-icon-theme.files.associations": {
      "package.json": "npm",
      "package-lock.json": "npm"
    },
    "prettier.jsxBracketSameLine": true,
    "prettier.printWidth": 120,
    "prettier.resolveGlobalModules": true,
    "prettier.trailingComma": "none"
  }
EOT
}

main() {
  uninstall_packages
  setup_environment
  install_fonts
  install_chrome
  install_docker
  install_go
  install_node
  install_terraform
  install_vscode
}

main