#!/usr/bin/env bash
set -e

echo "Installing fd..."

REPO="sharkdp/fd"

# Check if running as root
if [ "$(id -u)" -ne 0 ]; then
    echo "Script must be run as root. Use sudo, su, or add \"USER root\" to your Dockerfile."
    exit 1
fi

# Set version - use latest if not specified
FEAT_VERSION=${VERSION:-"latest"}

# Get OS information
. /etc/os-release

# Detect architecture
ARCH=$(uname -m)
if [[ "$ARCH" == "aarch64" ]]; then
  ARCH="arm64"
elif [[ "$ARCH" == "x86_64" ]]; then
  ARCH="amd64"
fi

# Get latest version if requested
if [ "$FEAT_VERSION" = "latest" ]; then
  echo "Finding latest version..."
  if ! command -v curl &> /dev/null; then
    case "${ID}" in
      debian|ubuntu) apt-get update && apt-get install -y curl ca-certificates ;;
      alpine) apk add --no-cache curl ca-certificates ;;
    esac
  fi
  FEAT_VERSION=$(curl -s "https://api.github.com/repos/$REPO/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
fi

echo "Installing fd version ${FEAT_VERSION} / arch ${ARCH}..."

# Install based on distro
case "${ID}" in
  debian|ubuntu)
    # For Debian-based systems
    if ! command -v curl &> /dev/null; then
      apt-get update && apt-get install -y curl ca-certificates
    fi
    # https://github.com/sharkdp/fd/releases/download/v10.2.0/fd_10.2.0_amd64.deb
    curl -sSL -o /tmp/fd.deb "https://github.com/$REPO/releases/download/v${FEAT_VERSION}/fd_${FEAT_VERSION}_${ARCH}.deb"
    dpkg -i /tmp/fd.deb
    rm -f /tmp/fd.deb
    ;;
  alpine)
    # For Alpine
    if ! command -v curl &> /dev/null; then
      apk add --no-cache curl ca-certificates
    fi
    # https://github.com/sharkdp/fd/releases/download/v10.2.0/fd-v10.2.0-x86_64-unknown-linux-musl.tar.gz
    curl -sSL -o /tmp/fd.tar.gz "https://github.com/$REPO/releases/download/v${FEAT_VERSION}/fd-v${FEAT_VERSION}-${ARCH}-unknown-linux-musl.tar.gz"
    tar xf /tmp/fd.tar.gz -C /tmp
    mv "/tmp/fd-${FEAT_VERSION}-linux-${ARCH}/fd" /usr/local/bin/
    rm -rf /tmp/fd.tar.gz "/tmp/fd-${FEAT_VERSION}-linux-${ARCH}"
    ;;
  *)
    echo "Unsupported distribution: ${ID}"
    exit 1
    ;;
esac

# Verify installation
echo "Verifying installation..."
fd --version

# Clean up package lists on Debian/Ubuntu
if [ "${ID}" = "debian" ] || [ "${ID}" = "ubuntu" ]; then
  rm -rf /var/lib/apt/lists/*
fi

echo "Done!"
