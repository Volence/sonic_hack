#!/usr/bin/env bash
set -euo pipefail

# EDIT these paths if yours differ
LEVEL_DIR="art/kosinski"          # where EHZ.bin, HTZ_Main.bin, etc live
OUT_DIR="build/meta"
OUT_ASM="${OUT_DIR}/level_art_sizes.asm"

# Tools (only needed if you really have .kos files)
KOSDEC="${KOSDEC:-tools/kosdec}"  # clownlzss multi-tool

mkdir -p "$OUT_DIR"

upper_name() {
  # basename -> UPPER and non-alnum -> _
  # examples: EHZ.bin -> EHZ ; HTZ_Main.bin -> HTZ_MAIN ; CPZ-DEZ.bin -> CPZ_DEZ
  local base="${1%.*}"
  echo "$base" | tr '[:lower:]-.' '[:upper:]__' | sed 's/[^A-Z0-9_]/_/g'
}

bytes_to_tiles_hex() {
  local bytes="$1"
  local tiles=$(( bytes / 32 ))
  printf "\$%04X" "$tiles"
}

# temp map for main/sup combos
declare -A have_main have_sup

{
  echo "; ---------------------------------------------------------------------------"
  echo "; Generated – include from S4.constants.asm for reference (not linked into game)"
  echo "; ---------------------------------------------------------------------------"
  echo "ArtTile_ArtKos_LevelArt               = \$0000"
  echo

  shopt -s nullglob

  for f in "$LEVEL_DIR"/*; do
    name="$(upper_name "$(basename "$f")")"   # e.g., HTZ_MAIN
    ext="${f##*.}"

    # Produce a raw output size: for .bin assume raw; for .kos try to decompress
    if [[ "$ext" == "bin" ]]; then
      bytes=$(stat -c%s "$f")
    elif [[ "$ext" == "kos" ]]; then
      # Decompress to temp and count
      tmp="$(mktemp)"
      if "$KOSDEC" -k -d "$f" "$tmp" 2>/dev/null; then
        bytes=$(stat -c%s "$tmp")
        rm -f "$tmp"
      else
        echo "; WARN: failed to decompress $f – treating as raw" >&2
        bytes=$(stat -c%s "$f")
      fi
    else
      echo "; SKIP: $f (unknown extension)" >&2
      continue
    fi

    tiles_hex=$(bytes_to_tiles_hex "$bytes")
    printf "ArtTile_ArtKos_NumTiles_%-20s = %s\n" "$name" "$tiles_hex"

    # track for auto-combine
    zone="${name%_*}"    # HTZ_MAIN -> HTZ
    tail="${name#${zone}_}"  # MAIN / SUP / same
    if [[ "$tail" == "MAIN" ]]; then
      have_main["$zone"]=1
    elif [[ "$tail" == "SUP" ]]; then
      have_sup["$zone"]=1
    fi
  done

  echo

  # Auto-emit combined TOTAL = MAIN + SUP - 1 where both exist
  for z in "${!have_main[@]}"; do
    if [[ -n "${have_sup[$z]:-}" ]]; then
      echo "ArtTile_ArtKos_NumTiles_${z}           = ArtTile_ArtKos_NumTiles_${z}_MAIN + ArtTile_ArtKos_NumTiles_${z}_SUP - 1"
    fi
  done

  echo "; ---------------------------------------------------------------------------"
} > "$OUT_ASM"

echo "Wrote $OUT_ASM"
