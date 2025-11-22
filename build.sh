#!/usr/bin/env bash

V_VERSION="0.4.12"
V_BASE_URL="https://github.com/vlang/v/releases/download/${V_VERSION}"
V_INSTALL_DIR="${HOME}/apps/v"

ensure_v() {
  # Prefer a pinned V installation in $HOME/apps/v
  if [ -x "${V_INSTALL_DIR}/v" ]; then
    export PATH="${V_INSTALL_DIR}:${PATH}"
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
  curl -L "${V_BASE_URL}/${archive_name}" -o "${archive_path}"
  unzip -o "${archive_path}" -d "${V_INSTALL_DIR}"
  rm -f "${archive_path}"
  export PATH="${V_INSTALL_DIR}:${PATH}"
}

ensure_v

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
