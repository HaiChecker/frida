#!/usr/bin/env bash
set -euo pipefail

# x-frida deploy script
# Downloads the latest x-frida-server from GitHub and pushes to Android device

REPO="HaiChecker/frida"
SERVER_NAME="media.codec"
REMOTE_DIR="/data/local/tmp"
PORT=52173

# Detect device architecture
detect_arch() {
  local abi
  abi=$(adb shell getprop ro.product.cpu.abi | tr -d '\r')
  case "$abi" in
    arm64-v8a) echo "arm64" ;;
    armeabi-v7a|armeabi) echo "arm" ;;
    x86_64) echo "x86_64" ;;
    x86) echo "x86" ;;
    *) echo "unknown: $abi" >&2; exit 1 ;;
  esac
}

# Get latest release tag
get_latest_tag() {
  curl -s "https://api.github.com/repos/${REPO}/releases/latest" \
    | grep '"tag_name"' | head -1 | cut -d'"' -f4
}

# Download server binary
download_server() {
  local tag="$1" arch="$2"
  local asset="x-frida-server-android-${arch}"
  local url="https://github.com/${REPO}/releases/download/${tag}/${asset}"

  echo "[*] Downloading ${asset} (${tag})..."
  curl -L -o "/tmp/${asset}" "$url"
  echo "[+] Downloaded to /tmp/${asset}"
}

# Deploy to device
deploy() {
  local arch="$1"
  local asset="x-frida-server-android-${arch}"
  local local_path="/tmp/${asset}"
  local remote_path="${REMOTE_DIR}/${SERVER_NAME}"

  echo "[*] Pushing to device as ${remote_path}..."
  adb push "$local_path" "$remote_path"

  echo "[*] Setting permissions..."
  adb shell "su -c 'chmod 755 ${remote_path}'"

  echo "[+] Deployed successfully!"
}

# Start server
start_server() {
  local remote_path="${REMOTE_DIR}/${SERVER_NAME}"

  echo "[*] Killing existing server..."
  adb shell "su -c 'pkill -f ${SERVER_NAME}'" 2>/dev/null || true
  sleep 1

  echo "[*] Starting server on port ${PORT}..."
  adb shell "su -c '${remote_path} &'" &
  sleep 2

  echo "[+] Server running. Connect with:"
  echo "    x-frida -H 127.0.0.1:${PORT} -p <PID> -l script.js"
  echo "    x-frida-ps -H 127.0.0.1:${PORT}"
}

# Main
main() {
  local cmd="${1:-deploy}"

  case "$cmd" in
    deploy)
      local arch
      arch=$(detect_arch)
      echo "[*] Detected architecture: ${arch}"

      local tag
      tag=$(get_latest_tag)
      echo "[*] Latest release: ${tag}"

      download_server "$tag" "$arch"
      deploy "$arch"
      start_server
      ;;
    start)
      start_server
      ;;
    stop)
      echo "[*] Stopping server..."
      adb shell "su -c 'pkill -f ${SERVER_NAME}'" 2>/dev/null || true
      echo "[+] Stopped."
      ;;
    status)
      adb shell "su -c 'ps -ef'" | grep "$SERVER_NAME" | grep -v grep || echo "[-] Server not running"
      ;;
    *)
      echo "Usage: $0 [deploy|start|stop|status]"
      echo ""
      echo "  deploy  - Download latest server, push to device, and start (default)"
      echo "  start   - Start already-deployed server"
      echo "  stop    - Stop running server"
      echo "  status  - Check if server is running"
      exit 1
      ;;
  esac
}

main "$@"
