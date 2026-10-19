#!/usr/bin/env bash
# pwnbox ISO builder
#
# Builds the live and/or installer ISO images from this flake
# (.#images.<system>.{live,installer}) and copies them to iso/.
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$SCRIPT_DIR"
LOG="${TMPDIR:-/tmp}/pwnbox-iso.log"
OUT_TMP="${TMPDIR:-/tmp}/pwnbox-iso.out"

C_RESET=""
C_BOLD=""
C_DIM=""
C_BLUE=""
C_GREEN=""
C_YELLOW=""
C_RED=""

# pwnbox's flake defines these image architectures (see isoSystems in flake.nix)
SUPPORTED_ARCHS="x86_64-linux aarch64-linux"

images=()
arch=""
builders=""
out_dir=""
usb_dev=""
keep_result=0
verbose=0
no_build=0
want_help=0
had_args=$#

usage_text() {
    printf '\n'
    printf '  %sUSAGE%s\n' "${C_BLUE:-}${C_BOLD:-}" "${C_RESET:-}"
    printf '    %s./build-iso.sh [IMAGE...] [OPTIONS]%s\n' "${C_DIM:-}" "${C_RESET:-}"
    printf '    %sBuild pwnbox ISO images (live desktop and/or installer).%s\n' "${C_DIM:-}" "${C_RESET:-}"
    printf '    %sWith no IMAGE argument, both images are built.%s\n' "${C_DIM:-}" "${C_RESET:-}"

    printf '\n  %sIMAGES%s\n' "${C_BLUE:-}${C_BOLD:-}" "${C_RESET:-}"
    printf '    %-15s %s\n' "live" "pwnbox live desktop (RAM-backed, zero-trace)"
    printf '    %-15s %s\n' "installer" "stock NixOS installer with the flake at /pwnbox"

    printf '\n  %sOPTIONS%s\n' "${C_BLUE:-}${C_BOLD:-}" "${C_RESET:-}"
    printf '    %-16s %s\n' "-a, --arch ARCH" "target architecture [default: this machine]"
    printf '    %-16s %s\n' "   --builders SPEC" "remote builders for a foreign arch, e.g. 'ssh-ng://root@pi aarch64-linux - 8'"
    printf '    %-16s %s\n' "-o, --out DIR" "copy finished ISOs into DIR [default: $FLAKE_DIR/iso]"
    printf '    %-16s %s\n' "-u, --usb DEV" "dd the ISO to DEV after building (one image only)"
    printf '    %-16s %s\n' "--keep-result" "keep the ./result-* symlinks (default: removed)"
    printf '    %-16s %s\n' "-n, --no-build" "evaluate the config only, do not build"
    printf '    %-16s %s\n' "-v, --verbose" "stream all command output (default: quiet)"
    printf '    %-16s %s\n' "-h, --help" "show this help"

    printf '\n  %sARCHITECTURES%s\n' "${C_BLUE:-}${C_BOLD:-}" "${C_RESET:-}"
    printf '    %-18s %s\n' "x86_64-linux" "BIOS + UEFI; builds natively on x86_64"
    printf '    %-18s %s\n' "aarch64-linux" "UEFI only; needs an ARM builder or binfmt emulation"

    printf '\n  %sEXAMPLES%s\n' "${C_BLUE:-}${C_BOLD:-}" "${C_RESET:-}"
    printf '    %s./build-iso.sh%s\n' "${C_DIM:-}" "${C_RESET:-}"
    printf '    %s./build-iso.sh live%s\n' "${C_DIM:-}" "${C_RESET:-}"
    printf '    %s./build-iso.sh installer -a aarch64-linux --builders "ssh-ng://root@pi aarch64-linux - 8"%s\n' "${C_DIM:-}" "${C_RESET:-}"
    printf '    %s./build-iso.sh live -u /dev/sdb%s\n' "${C_DIM:-}" "${C_RESET:-}"
    printf '\n'
}

usage() { usage_text; }

while [ "$#" -gt 0 ]; do
    case "$1" in
    live | installer)
        images+=("$1")
        shift
        ;;
    -a | --arch)
        if [ "$#" -lt 2 ]; then
            echo "build-iso.sh: --arch needs a value" >&2
            exit 2
        fi
        arch="$2"
        shift 2
        ;;
    --arch=*)
        arch="${1#*=}"
        shift
        ;;
    --builders)
        if [ "$#" -lt 2 ]; then
            echo "build-iso.sh: --builders needs a value" >&2
            exit 2
        fi
        builders="$2"
        shift 2
        ;;
    --builders=*)
        builders="${1#*=}"
        shift
        ;;
    -o | --out)
        if [ "$#" -lt 2 ]; then
            echo "build-iso.sh: --out needs a value" >&2
            exit 2
        fi
        out_dir="$2"
        shift 2
        ;;
    --out=*)
        out_dir="${1#*=}"
        shift
        ;;
    -u | --usb)
        if [ "$#" -lt 2 ]; then
            echo "build-iso.sh: --usb needs a value" >&2
            exit 2
        fi
        usb_dev="$2"
        shift 2
        ;;
    --usb=*)
        usb_dev="${1#*=}"
        shift
        ;;
    --keep-result)
        keep_result=1
        shift
        ;;
    -n | --no-build)
        no_build=1
        shift
        ;;
    -v | --verbose)
        verbose=1
        shift
        ;;
    -h | --help)
        want_help=1
        shift
        ;;
    *)
        echo "build-iso.sh: unknown argument '$1'" >&2
        usage >&2
        exit 2
        ;;
    esac
done

if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    C_RESET=$'\033[0m'
    C_BOLD=$'\033[1m'
    C_DIM=$'\033[2m'
    C_BLUE=$'\033[34m'
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_RED=$'\033[31m'
else
    C_RESET=""
    C_BOLD=""
    C_DIM=""
    C_BLUE=""
    C_GREEN=""
    C_YELLOW=""
    C_RED=""
fi

step() {
    STEP_N=$((STEP_N + 1))
    printf '%s(%d/%d)%s %s%s%s\n' "$C_BLUE$C_BOLD" "$STEP_N" "$STEP_TOTAL" "$C_RESET" "$C_BOLD" "$*" "$C_RESET"
}
info() { printf '      %s%s%s\n' "$C_DIM" "$*" "$C_RESET"; }
ok() { printf '\n%sok%s  %s%s%s\n' "$C_GREEN" "$C_RESET" "$C_BOLD" "$*" "$C_RESET"; }
warn() { printf '%s==> %s%s\n' "$C_YELLOW" "$*" "$C_RESET" >&2; }
die() {
    printf '%s==> %s%s\n' "$C_RED" "$*" "$C_RESET" >&2
    exit 1
}

banner() {
    cat <<'EOF'
                                                ____         ______
|`````````, `.               .' |..          | |    ~.     .~      ~.   ``..      ..''
|'''''''''    `.           .'   |  ``..      | |____.'_   |          |      ``..''
|               `.   .   .'     |      ``..  | |       ~. |          |      ..'`
|                 `.' `.'       |          ``| |_______.'  `.______.'   ..''      ``..
EOF
}

run() {
    if [ "$verbose" -eq 1 ]; then
        "$@"
    else
        "$@" >/dev/null 2>&1
    fi
}

help_screen() {
    printf '%s\n' "$C_BLUE$C_BOLD"
    banner
    printf '%s\n' "$C_RESET"
    usage_text
}

if [ "$want_help" -eq 1 ]; then
    help_screen
    exit 0
fi

[ -t 1 ] && clear

if [ "$had_args" -eq 0 ] && [ -t 0 ]; then
    help_screen
    printf '\n  %sbuild live + installer for this machine?%s [Y/n] ' "$C_BOLD" "$C_RESET"
    read -r ans || true
    case "$ans" in
    [Nn]*)
        printf '  %saborted%s\n' "$C_DIM" "$C_RESET"
        exit 0
        ;;
    esac
elif [ -t 1 ]; then
    printf '%s\n' "$C_BLUE$C_BOLD"
    banner
    printf '%s\n' "$C_RESET"
fi

[ ${#images[@]} -gt 0 ] || images=(live installer)

if [ "$no_build" -eq 1 ] && [ -n "$usb_dev" ]; then
    die "--usb cannot be combined with --no-build"
fi

if [ -n "$usb_dev" ] && [ ${#images[@]} -gt 1 ]; then
    die "--usb needs exactly one image, got: ${images[*]}"
fi

if [ -n "$usb_dev" ] && [ ! -b "$usb_dev" ]; then
    die "not a block device: $usb_dev"
fi

if [ ! -f "$FLAKE_DIR/flake.nix" ]; then
    die "no flake.nix found in $FLAKE_DIR"
fi

command -v nix >/dev/null 2>&1 || die "nix not found in PATH"

host_system="$(nix eval --impure --raw --expr builtins.currentSystem 2>/dev/null || true)"
host_system="${host_system:-unknown}"

if [ -z "$arch" ]; then
    case "$host_system" in
    x86_64-linux | aarch64-linux) arch="$host_system" ;;
    *)
        arch="x86_64-linux"
        warn "host system '$host_system' is not an ISO target, defaulting to x86_64-linux"
        ;;
    esac
fi

case " $SUPPORTED_ARCHS " in
*" $arch "*) ;;
*)
    die "unsupported architecture '$arch' (supported: $SUPPORTED_ARCHS)"
    ;;
esac

if [ "$arch" != "$host_system" ]; then
    if [ -n "$builders" ]; then
        info "building $arch on $host_system with builders: $builders"
    elif [ -r "/proc/sys/fs/binfmt_misc/qemu-aarch64" ]; then
        warn "building $arch under binfmt emulation — this can take many hours"
        warn "a real ARM builder is much faster (--builders)"
    else
        die "building $arch on $host_system needs --builders (e.g. 'ssh-ng://root@pi $arch - 8') or binfmt emulation"
    fi
fi

out_dir="${out_dir:-$FLAKE_DIR/iso}"
mkdir -p "$out_dir"

# the flake only sees git-tracked files; warn about untracked ones so a fresh
# hosts/iso edit doesn't silently build the old version
if command -v git >/dev/null 2>&1 && git -C "$FLAKE_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    untracked="$(git -C "$FLAKE_DIR" ls-files --others --exclude-standard | sed "s|^|      |" | head -n 5)"
    if [ -n "$untracked" ]; then
        warn "untracked files are invisible to the flake (git add them first):"
        printf '%s\n' "$untracked" >&2
    fi
fi

STEP_N=0
STEP_TOTAL=${#images[@]}
if [ "$no_build" -eq 0 ] && [ -n "$usb_dev" ]; then
    STEP_TOTAL=$((STEP_TOTAL + 1))
fi

header() {
    printf '%s pwnbox ISO%s  %s· %s%s\n' "$C_BOLD" "$C_RESET" "$C_DIM" "$FLAKE_DIR" "$C_RESET"
    printf '\n'
    printf '  %-8s %-18s %-8s %s\n' "arch" "$arch" "host" "$host_system"
    printf '  %-8s %-18s %-8s %s\n' "images" "${images[*]}" "out" "$out_dir"
    printf '\n'
}
header

: >"$LOG"

run_nix() {
    # stdout (the store path) goes to $OUT_TMP, nix chatter to $LOG (or both)
    if [ "$verbose" -eq 1 ]; then
        "$@" 2> >(tee -a "$LOG" >&2) | tee "$OUT_TMP"
    else
        "$@" 2>>"$LOG" | tee "$OUT_TMP" >/dev/null
    fi
    return "${PIPESTATUS[0]}"
}

fail_log() {
    warn "Build failed (exit $1)"
    if [ "$verbose" -eq 0 ]; then
        printf '\n%s---- last lines of the log ----%s\n' "$C_DIM" "$C_RESET"
        tail -n 40 "$LOG" || true
        printf '%s--------------------------------%s\n\n' "$C_DIM" "$C_RESET"
        info "full log: $LOG  (rerun with --verbose)"
    fi
    exit "$1"
}

built_isos=()

for image in "${images[@]}"; do
    step "building $image ISO for $arch"
    info "this can take a while"

    nix_args=(build ".#images.$arch.$image" --no-link --print-out-paths)
    [ -n "$builders" ] && nix_args+=(--builders "$builders")

    if [ "$no_build" -eq 1 ]; then
        nix_args=(eval ".#images.$arch.$image.drvPath")
        if run_nix nix "${nix_args[@]}" >/dev/null; then
            info "$image config evaluates for $arch"
            continue
        else
            fail_log $?
        fi
    fi

    if ! run_nix nix "${nix_args[@]}"; then
        fail_log $?
    fi
    out_path="$(tail -n 1 "$OUT_TMP" | tr -d '[:space:]')"

    iso_file="$(find "$out_path" -maxdepth 2 -name '*.iso' -print -quit 2>/dev/null || true)"
    if [ -z "$iso_file" ]; then
        die "no .iso found in $out_path"
    fi

    dest="$out_dir/pwnbox-${image}-${arch}.iso"
    run rm -f "$dest"
    run cp "$iso_file" "$dest"
    built_isos+=("$dest")

    info "size : $(du -h "$dest" | cut -f1)"
    info "sha256: $(sha256sum "$dest" | cut -d' ' -f1)"
done

if [ "$no_build" -eq 1 ]; then
    ok "All configs evaluate for $arch (no build)"
    exit 0
fi

if [ "$keep_result" -eq 0 ]; then
    rm -f "$FLAKE_DIR"/result*
fi

ok "Built ${#built_isos[@]} image(s) for $arch"
for iso in "${built_isos[@]}"; do
    printf '      %s%s%s\n' "$C_BOLD" "$iso" "$C_RESET"
done

if [ -n "$usb_dev" ]; then
    step "writing ${built_isos[0]} to $usb_dev"
    warn "this will DESTROY all data on $usb_dev"
    printf '  %swrite to %s?%s [y/N] ' "$C_BOLD" "$usb_dev" "$C_RESET"
    read -r ans || true
    case "$ans" in
    [Yy]*)
        sudo dd if="${built_isos[0]}" of="$usb_dev" bs=4M conv=fsync status=progress
        ok "written to $usb_dev — boot it, or copy the ISO to a Ventoy stick instead"
        ;;
    *)
        info "skipped USB write; the ISO is at ${built_isos[0]}"
        ;;
    esac
else
    info "flash it with:  sudo dd if=${built_isos[0]} of=/dev/sdX bs=4M conv=fsync status=progress"
fi
