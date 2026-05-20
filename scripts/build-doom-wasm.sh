#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC_DIR="${DOOM_SRC_DIR:-$ROOT_DIR/DOOM/linuxdoom-1.10}"
PLATFORM_DIR="${DOOM_PLATFORM_DIR:-$ROOT_DIR/wasm}"
OUT_DIR="$ROOT_DIR/public/engine"

if [[ ! -d "$SRC_DIR" ]]; then
  printf 'Doom source directory not found: %s\n' "$SRC_DIR" >&2
  printf 'Set DOOM_SRC_DIR to the linuxdoom-1.10 source directory.\n' >&2
  exit 1
fi

for platform_file in i_video_ems.c i_sound_ems.c i_net_ems.c; do
  if [[ ! -f "$PLATFORM_DIR/$platform_file" ]]; then
    printf 'Doom browser platform file not found: %s\n' "$PLATFORM_DIR/$platform_file" >&2
    printf 'Set DOOM_PLATFORM_DIR to the adapter source directory.\n' >&2
    exit 1
  fi
done

mkdir -p "$OUT_DIR"

SRC_FILES=()
while IFS= read -r file; do
  SRC_FILES+=("$file")
done < <(find "$SRC_DIR" -maxdepth 1 -name '*.c' \
  ! -name 'i_video.c' ! -name 'i_sound.c' ! -name 'i_net.c')

SRC_FILES+=("$PLATFORM_DIR/i_video_ems.c" "$PLATFORM_DIR/i_sound_ems.c" "$PLATFORM_DIR/i_net_ems.c")

emcc "${SRC_FILES[@]}" \
  -I"$SRC_DIR" \
  -include "$PLATFORM_DIR/doom_emscripten_compat.h" \
  -O2 \
  -DNORMALUNIX \
  -s USE_SDL=2 \
  -s ASYNCIFY=1 \
  -s ALLOW_MEMORY_GROWTH=1 \
  -s MODULARIZE=1 \
  -s EXPORT_ES6=1 \
  -s ENVIRONMENT=web \
  -s EXIT_RUNTIME=0 \
  -s NO_EXIT_RUNTIME=1 \
  -s "EXPORTED_RUNTIME_METHODS=['FS','FS_createDataFile','FS_analyzePath','FS_createPath','FS_chdir']" \
  -s FILESYSTEM=1 \
  -o "$OUT_DIR/doom.js"
