#!/usr/bin/env bash
set -euo pipefail

V_VERSION="0.4.12"
V_BASE_URL="https://github.com/vlang/v/releases/download/${V_VERSION}"
V_INSTALL_DIR="${HOME}/apps/v"

ensure_v() {
  local v_bin_dir=""

  # Prefer a pinned V installation in $HOME/apps/v. The official
  # release zips unpack into $V_INSTALL_DIR/v, so handle both layouts.
  if [ -f "${V_INSTALL_DIR}/v" ] && [ -x "${V_INSTALL_DIR}/v" ]; then
    v_bin_dir="${V_INSTALL_DIR}"
  elif [ -f "${V_INSTALL_DIR}/v/v" ] && [ -x "${V_INSTALL_DIR}/v/v" ]; then
    v_bin_dir="${V_INSTALL_DIR}/v"
  fi

  if [ -n "${v_bin_dir}" ]; then
    export PATH="${v_bin_dir}:${PATH}"
    return
  fi

  # Fall back to system v if present
  if command -v v >/dev/null 2>&1; then
    return
  fi

  echo "V not found; downloading ${V_VERSION}..."
  mkdir -p "${V_INSTALL_DIR}"

  arch="$(uname -m)"
  os_name="$(uname -s)"
  case "${os_name}" in
    Darwin)
      case "${arch}" in
        x86_64|amd64) archive_name="v_macos_x86_64.zip" ;;
        arm64|aarch64) archive_name="v_macos_arm64.zip" ;;
        *) echo "Unsupported macOS architecture: ${arch}" >&2; exit 1 ;;
      esac
      ;;
    Linux)
      case "${arch}" in
        x86_64|amd64) archive_name="v_linux.zip" ;;
        arm64|aarch64) archive_name="v_linux_arm64.zip" ;;
        *) echo "Unsupported Linux architecture: ${arch}" >&2; exit 1 ;;
      esac
      ;;
    *)
      echo "Unsupported OS: ${os_name}" >&2
      exit 1
      ;;
  esac

  archive_path="/tmp/${archive_name}"
  if ! command -v unzip >/dev/null 2>&1; then
    echo "unzip is required to install V" >&2
    exit 1
  fi

  curl -fSLo "${archive_path}" "${V_BASE_URL}/${archive_name}"
  unzip -o "${archive_path}" -d "${V_INSTALL_DIR}"
  rm -f "${archive_path}"

  if [ -f "${V_INSTALL_DIR}/v/v" ] && [ -x "${V_INSTALL_DIR}/v/v" ]; then
    v_bin_dir="${V_INSTALL_DIR}/v"
  elif [ -f "${V_INSTALL_DIR}/v" ] && [ -x "${V_INSTALL_DIR}/v" ]; then
    v_bin_dir="${V_INSTALL_DIR}"
  else
    echo "V install missing 'v' executable after unzip" >&2
    exit 1
  fi

  export PATH="${v_bin_dir}:${PATH}"
}

ensure_v

# Avoid interactive prompts from V in CI/non-interactive shells
export VPM_AUTOINSTALL=${VPM_AUTOINSTALL:-yes}
export CI=${CI:-1}

if ! command -v v >/dev/null 2>&1; then
  echo "v compiler not available after install attempt" >&2
  exit 1
fi

# Build the projects
if [ ! -d bin ]; then
  mkdir bin
fi

# configure compile flags
COMP_FLAGS="-prod -skip-unused"
# if linux then add -cflags -static
if [ "$(uname)" == "Linux" ]; then
	COMP_FLAGS="$COMP_FLAGS -compress -cflags -static"
fi

# copy the v executabe to bin
# build and copy executables
v ${COMP_FLAGS} -o bin/urlencode $PWD/src/utils/urlencode.v
v ${COMP_FLAGS} -o bin/urldecode $PWD/src/utils/urldecode.v
v ${COMP_FLAGS} -o bin/epoch $PWD/src/utils/epoch.v
v ${COMP_FLAGS} -o bin/loop $PWD/src/utils/loop.v
v ${COMP_FLAGS} -o bin/swap $PWD/src/utils/swap.v
v ${COMP_FLAGS} -o bin/media $PWD/src/media
v ${COMP_FLAGS} -o bin/update $PWD/src/update
v ${COMP_FLAGS} -o bin/paths $PWD/src/utils/paths.v
v ${COMP_FLAGS} -o bin/filecache $PWD/src/filecache
v ${COMP_FLAGS} -o bin/nerdfont $PWD/src/nerdfont
v ${COMP_FLAGS} -o bin/organize $PWD/src/organize
v ${COMP_FLAGS} -o bin/bookmark $PWD/src/bookmark
v ${COMP_FLAGS} -o bin/docgen $PWD/src/docgen

tar -czvf bin.tgz bin/*
