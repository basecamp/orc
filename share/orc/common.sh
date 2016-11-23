#!/usr/bin/env bash

SHARE_DIR="$_ORC_ROOT/share/orc"
TMP_DIR="$_ORC_ROOT/tmp"
OPENSSL=$(which openssl)
DOCKER=$(which docker)
RSYNC=$(which rsync)

silently() {
  $@ 2>&1 >/dev/null
}

silently_log() {
  echo -n "$(date "+%Y-%m-%dT%H:%M:%S") " >> /tmp/orc_setup.log
  $@ 2>&1 >> /tmp/orc_setup.log
}

resolve_link() {
  $(type -p greadlink readlink | head -1) $1
}

abs_dirname() {
  local cwd="$(pwd)"
  local path="$1"

  while [ -n "$path" ]; do
    cd "${path%/*}"
    local name="${path##*/}"
    path="$(resolve_link "$name" || true)"
  done

  pwd
  cd "$cwd"
}
