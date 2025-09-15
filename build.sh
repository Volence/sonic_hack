#!/usr/bin/env bash
# build.sh — Linux/Bash port of the original build.bat

# NOTES:
# - By default this script tries to run Windows binaries via Wine.
#   You can override the runner by exporting WINE="" to run native tools if you have them.
#   Example: WINE="" ./build.sh
# - The original batch used labels and gotos; here we use functions + early exits.
# - The behavior (including oddities like the final s4.p check) is preserved.

set -u  # (avoid -e so we can emulate the batch's conditional flow)

# Silence Wine debug output (remove this line if you want it verbose)
export WINEDEBUG=${WINEDEBUG:--all}

# --- Configuration / helpers --------------------------------------------------

WINE=${WINE:-wine}  # set to "" if your tools are native linux binaries

die() {
  echo "$*" >&2
  exit 1
}

# Run a tool that may be a native binary or a Windows .exe
# Usage: run_tool ./path/to/tool [args...]
run_tool() {
  local tool="$1"; shift || true

  if [[ -x "$tool" ]]; then
    # Native executable present
    "$tool" "$@"
  elif [[ -f "${tool}.exe" ]]; then
    # Windows exe next to it
    if [[ -n "$WINE" ]]; then
      "$WINE" "${tool}.exe" "$@"
    else
      die "Cannot run ${tool}.exe without Wine. Set WINE=wine or provide a native binary."
    fi
  else
    # Fallback: try as given (may still be on PATH), else try wine directly
    if command -v "$tool" >/dev/null 2>&1; then
      "$tool" "$@"
    elif [[ -n "$WINE" ]]; then
      "$WINE" "$tool" "$@"
    else
      die "Tool not found: $tool"
    fi
  fi
}

# --- Step 1: Make s4.bin writable & back it up to s4.prev.bin -----------------

if [[ -e s4.bin ]]; then
  if [[ -e s4.prev.bin ]]; then
    rm -f s4.prev.bin || true
  fi
  if [[ -e s4.prev.bin ]]; then
    # LABLNOCOPY in the .bat: skip move if we still can't remove the old backup
    :
  else
    mv -f s4.bin s4.prev.bin || true
    if [[ -e s4.bin ]]; then
      # LABLERROR3
      die "Failed to build because write access to s4.bin was denied."
    fi
    # (In the batch there's a commented-out restore line; we preserve behavior)
  fi
fi

# --- Step 2: Delete intermediate assembler outputs if present -----------------

if [[ -e s4.p ]]; then
  rm -f s4.p || true
  if [[ -e s4.p ]]; then
    # LABLERROR2
    die "Failed to build because write access to s4.p was denied."
  fi
fi

if [[ -e s4.h ]]; then
  rm -f s4.h || true
  if [[ -e s4.h ]]; then
    # LABLERROR1
    die "Failed to build because write access to s4.h was denied."
  fi
fi

# --- Step 3: Clear the output window -----------------------------------------

# 'cls' on Windows; 'clear' on Linux
clear || true

# --- Step 4: Run the rings conversion program --------------------------------

if [[ -f level/rings/rings.exe || -x level/rings/rings || -f level/rings/rings ]]; then
  pushd level/rings >/dev/null || die "Could not cd to level/rings"
  # Prefer .exe via Wine if present, otherwise any native 'rings'
  if [[ -f rings.exe ]]; then
    if [[ -n "$WINE" ]]; then
      "$WINE" ./rings.exe
    else
      die "rings.exe present but WINE is disabled. Set WINE=wine or provide a native rings binary."
    fi
  else
    run_tool ./rings
  fi
  popd >/dev/null || true
fi

# --- Step 5: Set environment vars used by assembler --------------------------

export AS_MSGPATH="win32/msg"
export USEANSI="n"

# --- Step 6: Run the assembler (asw) -----------------------------------------

# Original logic:
# If "%1" == "-pe"  -> win32/asw -xx -c -A S4.asm
# else               -> win32/asw -xx -c -E -A S4.asm
ASW_OPTS=(-xx -c -A)
if [[ "${1-}" != "-pe" ]]; then
  ASW_OPTS=(-xx -c -E -A)
fi

run_tool ./win32/asw "${ASW_OPTS[@]}" S4.asm

# --- Step 7: If there were errors, a log file is produced --------------------

if [[ -e s4.log ]]; then
  echo
  echo "**********************************************************************"
  echo "*                                                                    *"
  echo "*   There were build errors/warnings. See s4.log for more details.   *"
  echo "*                                                                    *"
  echo "**********************************************************************"
  echo
  exit 1
fi

# --- Step 8: Combine the assembler output into a ROM -------------------------

# Grab case-insensitive filenames that the assembler actually produced
pfile=$(ls -1 [sS]4.[pP] 2>/dev/null | head -n1 || true)
hfile=$(ls -1 [sS]4.[hH] 2>/dev/null | head -n1 || true)

if [[ -z "${pfile}" || -z "${hfile}" ]]; then
  echo "Expected assembler outputs not found (looking for s4.p/S4.P and s4.h/S4.H)."
  echo "Found: p='${pfile:-<none>}' h='${hfile:-<none>}'"
  exit 1
fi

# Combine the assembler output into a ROM
run_tool ./win32/s4p2bin "${pfile}" s4.bin "${hfile}"

# --- Step 9: Fix pointers that can't be handled by the assembler -------------

if [[ -e s4.bin ]]; then
  # Make sure we know the header filename (case-insensitive)
  hfile=${hfile:-$(ls -1 [sS]4.[hH] 2>/dev/null | head -n1 || true)}

  if [[ -n "${hfile:-}" && -f "$hfile" ]]; then
    # Helper to test whole-word-ish symbol presence (case-insensitive)
    has_sym() {
      # match boundaries so "foo_bar" doesn't hit "foo_bar2"
      grep -qiE "(^|[^A-Za-z0-9_])$1([^A-Za-z0-9_]|$)" "$hfile"
    }

    # Build fix specs conditionally (only if BOTH symbols for a spec exist)
    fix_args=()

    # Spec 1
    if has_sym off_3A294 && has_sym MapRUnc_Sonic; then
      fix_args+=(off_3A294 MapRUnc_Sonic '$2D' 0 4)
    fi

    # Spec 2
    if has_sym word_728C_user && has_sym Obj5F_MapUnc_7240; then
      fix_args+=(word_728C_user Obj5F_MapUnc_7240 2 2 1)
    fi

    # Run fixpointer only if at least one spec was added
    if (( ${#fix_args[@]} > 0 )); then
      run_tool ./win32/fixpointer "$hfile" s4.bin "${fix_args[@]}"
    else
      echo "(skip) fixpointer: no matching symbols found in $hfile"
    fi
  else
    echo "(skip) fixpointer: header file not found"
  fi

  # Header checksum: keep or skip as you prefer.
  # If you want to run it always, leave this on; otherwise comment it out.
  run_tool ./win32/fixheader s4.bin
fi


# --- Step 10: Fix the ROM header (checksum) ----------------------------------

if [[ -e s4.bin ]]; then
  run_tool ./win32/fixheader s4.bin
fi

# --- Step 11: Done — replicate the .bat's final checks -----------------------

if [[ ! -e s4.p ]]; then
  # LABLPAUSE (no pause in Bash; just exit non-zero like the batch would hit `exit /b`)
  exit 1
fi

if [[ -e s4.bin ]]; then
  exit 0
fi

# Fallback exit (match batch behavior of falling through)
exit 0
