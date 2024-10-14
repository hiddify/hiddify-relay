#!/bin/bash

wstunnel_repo="https://api.github.com/repos/erebe/wstunnel/releases/latest"

function get_os_arch() {
  os=$(uname -s)
  arch=$(uname -m)

  case $os in
    Linux)
      case $arch in
        x86_64)
          echo "linux_amd64"
          ;;
        arm64)
          echo "linux_arm64"
          ;;
        armv7*)
          echo "linux_armv7"
          ;;
        i686)
          echo "linux_386"
          ;;
        *)
          echo "Unsupported Linux architecture: $arch"
          exit 1
          ;;
      esac
      ;;
    Darwin)
      case $arch in
        x86_64)
          echo "darwin_amd64"
          ;;
        arm64)
          echo "darwin_arm64"
          ;;
        *)
          echo "Unsupported Darwin architecture: $arch"
          exit 1
          ;;
      esac
      ;;
    *)
      echo "Unsupported operating system: $os"
      exit 1
      ;;
  esac
}

latest_release_json=$(curl -sSL "$wstunnel_repo")
os_arch=$(get_os_arch)
download_url=$(echo "$latest_release_json" | jq -r --arg os_arch "$os_arch" '.assets[] | select(.name | test("wstunnel_[^_]+_" + $os_arch + "\\.tar\\.gz")) | .browser_download_url')

if [[ -z "$download_url" ]]; then
  echo "Failed to find download URL for your OS/architecture."
  exit 1
fi

filename=$(basename "$download_url")
echo "Downloading $filename..."
curl -sSL "$download_url" -o "$filename" || { echo "Download failed!"; exit 1; }

echo "Extracting $filename..."
tar -xzf "$filename" || { echo "Extraction failed!"; exit 1; }

if [[ ! -f "wstunnel" ]]; then
  echo "Failed to find wstunnel binary in archive."
  exit 1
fi

echo "Moving wstunnel to /bin/wstunnel..."
sudo mv "wstunnel" /bin/wstunnel || { echo "Moving failed (requires root privileges)."; exit 1; }

echo "Setting permissions for /bin/wstunnel..."
sudo chmod +x /bin/wstunnel || { echo "Setting permissions failed (requires root privileges)."; exit 1; }

echo "wstunnel installation complete!"
