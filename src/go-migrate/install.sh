#!/usr/bin/env bash
set -e

echo "Installing go-migrate..."

REPO="golang-migrate/migrate"

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

echo "Installing go-migrate version ${FEAT_VERSION} / arch ${ARCH}..."

# Install based on distro
case "${ID}" in
  debian|ubuntu)
    # For Debian-based systems
    if ! command -v curl &> /dev/null; then
      apt-get update && apt-get install -y curl ca-certificates
    fi
    # https://github.com/golang-migrate/migrate/releases/download/v4.18.2/migrate.linux-arm64.deb
    curl -sSL -o /tmp/go-migrate.deb "https://github.com/$REPO/releases/download/v${FEAT_VERSION}/migrate.linux-${ARCH}.deb"
    dpkg -i /tmp/go-migrate.deb
    rm -f /tmp/go-migrate.deb
    ;;
  alpine)
    # For Alpine
    if ! command -v curl &> /dev/null; then
      apk add --no-cache curl ca-certificates
    fi
    curl -sSL -o /tmp/go-migrate.tar.gz "https://github.com/$REPO/releases/download/v${FEAT_VERSION}/migrate.linux-${ARCH}.tar.gz"
    tar xf /tmp/go-migrate.tar.gz -C /tmp
    mv "/tmp/go-migrate-${FEAT_VERSION}-linux-${ARCH}/go-migrate" /usr/local/bin/
    rm -rf /tmp/go-migrate.tar.gz "/tmp/go-migrate-${FEAT_VERSION}-linux-${ARCH}"
    ;;
  *)
    echo "Unsupported distribution: ${ID}"
    exit 1
    ;;
esac

# Verify installation
echo "Verifying installation..."
migrate --version

# Clean up package lists on Debian/Ubuntu
if [ "${ID}" = "debian" ] || [ "${ID}" = "ubuntu" ]; then
  rm -rf /var/lib/apt/lists/*
fi

echo "Done!"
