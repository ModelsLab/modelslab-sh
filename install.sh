#!/bin/sh
# ModelsLab CLI Installer
# Usage: curl -fsSL https://modelslab.sh/install.sh | sh
#
# This script detects your OS and architecture, downloads the appropriate
# ModelsLab CLI binary from GitHub releases, and installs it to /usr/local/bin.

set -e

REPO="ModelsLab/modelslab-cli"
BINARY_NAME="modelslab"
INSTALL_DIR="/usr/local/bin"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m'

info() { printf "${CYAN}info${NC}  %s\n" "$1"; }
ok() { printf "${GREEN}ok${NC}    %s\n" "$1"; }
warn() { printf "${YELLOW}warn${NC}  %s\n" "$1"; }
err() { printf "${RED}error${NC} %s\n" "$1" >&2; exit 1; }

# Detect OS
detect_os() {
  case "$(uname -s)" in
    Linux*)  echo "linux" ;;
    Darwin*) echo "darwin" ;;
    MINGW*|MSYS*|CYGWIN*) echo "windows" ;;
    *) err "Unsupported operating system: $(uname -s)" ;;
  esac
}

# Detect architecture
detect_arch() {
  case "$(uname -m)" in
    x86_64|amd64) echo "amd64" ;;
    arm64|aarch64) echo "arm64" ;;
    armv7*|armhf)  echo "arm" ;;
    i386|i686)     echo "386" ;;
    *) err "Unsupported architecture: $(uname -m)" ;;
  esac
}

# Get latest release tag from GitHub
get_latest_version() {
  if command -v curl > /dev/null 2>&1; then
    curl -fsSL "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/'
  elif command -v wget > /dev/null 2>&1; then
    wget -qO- "https://api.github.com/repos/${REPO}/releases/latest" | grep '"tag_name"' | sed -E 's/.*"tag_name": *"([^"]+)".*/\1/'
  else
    err "curl or wget is required"
  fi
}

# Download file
download() {
  local url="$1"
  local dest="$2"
  if command -v curl > /dev/null 2>&1; then
    curl -fsSL "$url" -o "$dest"
  elif command -v wget > /dev/null 2>&1; then
    wget -q "$url" -O "$dest"
  else
    err "curl or wget is required"
  fi
}

main() {
  printf "\n"
  printf "  ${CYAN}>_ ModelsLab CLI Installer${NC}\n"
  printf "\n"

  OS=$(detect_os)
  ARCH=$(detect_arch)
  info "Detected OS: ${OS}, Arch: ${ARCH}"

  info "Fetching latest release..."
  VERSION=$(get_latest_version)
  if [ -z "$VERSION" ]; then
    err "Could not determine latest version. Check https://github.com/${REPO}/releases"
  fi
  info "Latest version: ${VERSION}"

  # Determine the download filename
  # Expected format: modelslab_OS_ARCH.tar.gz (or .zip for Windows)
  if [ "$OS" = "windows" ]; then
    ARCHIVE="${BINARY_NAME}_${OS}_${ARCH}.zip"
  else
    ARCHIVE="${BINARY_NAME}_${OS}_${ARCH}.tar.gz"
  fi

  DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${VERSION}/${ARCHIVE}"
  info "Downloading ${DOWNLOAD_URL}..."

  TMP_DIR=$(mktemp -d)
  trap 'rm -rf "$TMP_DIR"' EXIT

  download "$DOWNLOAD_URL" "${TMP_DIR}/${ARCHIVE}"
  ok "Downloaded ${ARCHIVE}"

  # Extract
  info "Extracting..."
  cd "$TMP_DIR"
  if [ "$OS" = "windows" ]; then
    unzip -q "$ARCHIVE"
  else
    tar xzf "$ARCHIVE"
  fi

  # Install
  if [ -w "$INSTALL_DIR" ]; then
    mv "${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}"
  else
    info "Requesting sudo to install to ${INSTALL_DIR}..."
    sudo mv "${BINARY_NAME}" "${INSTALL_DIR}/${BINARY_NAME}"
  fi
  chmod +x "${INSTALL_DIR}/${BINARY_NAME}"

  ok "Installed ${BINARY_NAME} ${VERSION} to ${INSTALL_DIR}/${BINARY_NAME}"
  printf "\n"
  printf "  Run ${GREEN}modelslab --help${NC} to get started.\n"
  printf "\n"
}

main
