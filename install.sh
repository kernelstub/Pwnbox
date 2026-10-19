#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$SCRIPT_DIR"
LOG="${TMPDIR:-/tmp}/pwnbox-install.log"

C_RESET=""
C_BOLD=""
C_DIM=""
C_BLUE=""
C_GREEN=""
C_YELLOW=""
C_RED=""

action="switch"
do_gc=0
verbose=0
host=""
extra=()
want_help=0
had_args=$#

usage_text() {
    printf '\n'
    printf '  %sUSAGE%s\n' "${C_BLUE:-}${C_BOLD:-}" "${C_RESET:-}"
    printf '    %s./install.sh [ACTION] [OPTIONS] [-- EXTRA...]%s\n' "${C_DIM:-}" "${C_RESET:-}"
    printf '    %sRebuild this NixOS flake: build and activate the configuration.%s\n' "${C_DIM:-}" "${C_RESET:-}"
    printf '    %sGarbage collection is opt-in with --gc.%s\n' "${C_DIM:-}" "${C_RESET:-}"

    printf '\n  %sACTIONS%s\n' "${C_BLUE:-}${C_BOLD:-}" "${C_RESET:-}"
    printf '    %-15s %s\n' "switch" "build + activate, persistent [default]"
    printf '    %-15s %s\n' "test" "build + activate for this boot only"
    printf '    %-15s %s\n' "boot" "build + set as the default for the next boot"
    printf '    %-15s %s\n' "build" "build only, do not activate"
    printf '    %-15s %s\n' "dry-activate" "build + show what would change, do not activate"

    printf '\n  %sOPTIONS%s\n' "${C_BLUE:-}${C_BOLD:-}" "${C_RESET:-}"
    printf '    %-16s %s\n' "-H, --host HOST" "flake host to build (default: short hostname)"
    printf '    %-16s %s\n' "-g, --gc" "collect garbage first (deletes old generations)"
    printf '    %-16s %s\n' "-n, --no-gc" "keep old generations (default)"
    printf '    %-16s %s\n' "-v, --verbose" "stream all command output (default: quiet)"
    printf '    %-16s %s\n' "-h, --help" "show this help"

    printf '\n  %sEXAMPLES%s\n' "${C_BLUE:-}${C_BOLD:-}" "${C_RESET:-}"
    printf '    %s./install.sh%s\n' "${C_DIM:-}" "${C_RESET:-}"
    printf '    %s./install.sh build%s\n' "${C_DIM:-}" "${C_RESET:-}"
    printf '    %s./install.sh test -H nixos%s\n' "${C_DIM:-}" "${C_RESET:-}"
    printf '    %s./install.sh switch --verbose%s\n' "${C_DIM:-}" "${C_RESET:-}"
    printf '    %s./install.sh switch -- --show-trace%s\n' "${C_DIM:-}" "${C_RESET:-}"
    printf '\n'
}

usage() { usage_text; }

while [ "$#" -gt 0 ]; do
    case "$1" in
    switch | test | boot | build | dry-activate)
        action="$1"
        shift
        ;;
    -H | --host)
        if [ "$#" -lt 2 ]; then
            echo "install.sh: --host needs a value" >&2
            exit 2
        fi
        host="$2"
        shift 2
        ;;
    --host=*)
        host="${1#*=}"
        shift
        ;;
    -g | --gc)
        do_gc=1
        shift
        ;;
    -n | --no-gc)
        do_gc=0
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
    --)
        shift
        extra=("$@")
        break
        ;;
    *)
        echo "install.sh: unknown argument '$1'" >&2
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

header() {
    printf '%s pwnbox install%s  %s· %s%s\n' "$C_BOLD" "$C_RESET" "$C_DIM" "$FLAKE_DIR" "$C_RESET"
    printf '\n'
    printf '  %-8s %-18s %-8s %s\n' "host" "$host" "user" "$user"
    printf '  %-8s %-18s %-8s %s\n' "system" "$system" "action" "$action"
    printf '\n'
}

run() {
    if [ "$verbose" -eq 1 ]; then
        "$@"
    else
        "$@" >/dev/null 2>&1
    fi
}

banner() {
    cat <<'EOF'
                                                ____         ______
|`````````, `.               .' |..          | |    ~.     .~      ~.   ``..      ..''
|'''''''''    `.           .'   |  ``..      | |____.'_   |          |      ``..''
|               `.   .   .'     |      ``..  | |       ~. |          |      ..'`..
|                 `.' `.'       |          ``| |_______.'  `.______.'   ..''      ``..
EOF
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
    printf '\n  %sinstall with the defaults?%s [Y/n] ' "$C_BOLD" "$C_RESET"
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

if [ ! -f "$FLAKE_DIR/flake.nix" ]; then
    die "no flake.nix found in $FLAKE_DIR"
fi

command -v nixos-rebuild >/dev/null 2>&1 || die "nixos-rebuild not found in PATH"

if [ -z "$host" ]; then
    if command -v hostname >/dev/null 2>&1; then
        host="$(hostname -s 2>/dev/null || hostname)"
    fi
    host="${host:-nixos}"
fi

user="${PWNBOX_USER:-${SUDO_USER:-$(id -un 2>/dev/null || echo pwnbox)}}"
system="${PWNBOX_SYSTEM:-$(nix eval --impure --raw --expr builtins.currentSystem 2>/dev/null || echo x86_64-linux)}"

if [ "$(id -u)" -eq 0 ]; then
    SUDO=()
else
    SUDO=(sudo)
fi

home="$HOME"
if command -v getent >/dev/null 2>&1; then
    h="$(getent passwd "$user" 2>/dev/null | cut -d: -f6 || true)"
    [ -n "$h" ] && home="$h"
fi

STEP_N=0
STEP_TOTAL=2
host_dir="$FLAKE_DIR/hosts/$host"
if [ ! -f "$host_dir/default.nix" ]; then
    STEP_TOTAL=$((STEP_TOTAL + 1))
fi
STEP_TOTAL=$((STEP_TOTAL + 1))
STEP_TOTAL=$((STEP_TOTAL + 1))
need_sudo=0
[ "$do_gc" -eq 1 ] && need_sudo=1
[ "$action" != "build" ] && need_sudo=1
if [ "${#SUDO[@]}" -gt 0 ] && [ "$need_sudo" -eq 1 ]; then
    STEP_TOTAL=$((STEP_TOTAL + 1))
fi

header

for _c in kitty rofi fuzzel alacritty zathura; do
    _p="$home/.config/$_c"
    if [ -L "$_p" ]; then
        case "$(readlink "$_p")" in
        /nix/store/*home-manager-files/*)
            run rm -f "$_p"
            info "migrated ~/.config/$_c (directory link -> per-file)"
            ;;
        esac
    fi
done

host_dir="$FLAKE_DIR/hosts/$host"
if [ ! -f "$host_dir/default.nix" ]; then
    step "creating configuration for host '$host'"
    mkdir -p "$host_dir"
    cp "$FLAKE_DIR/hosts/nixos/default.nix" "$host_dir/default.nix"
    sed -i "s/hostName = \"nixos\"/hostName = \"$host\"/" "$host_dir/default.nix" 2>/dev/null || true
    sed -i 's/mainMonitor = "[^"]*"/mainMonitor = ""/; s/leftMonitor = "[^"]*"/leftMonitor = ""/' \
        "$host_dir/default.nix" 2>/dev/null || true

    tz="$(timedatectl show -p Timezone --value 2>/dev/null || true)"
    if [ -n "$tz" ]; then
        sed -i "s#timeZone = \"[^\"]*\"#timeZone = \"$tz\"#" "$host_dir/default.nix" 2>/dev/null || true
        info "time zone: $tz"
    fi
fi

step "refreshing machine-specific config"
if [ -f /etc/nixos/hardware-configuration.nix ] &&
    grep -q "fileSystems" /etc/nixos/hardware-configuration.nix; then
    cp /etc/nixos/hardware-configuration.nix "$host_dir/hardware-configuration.nix"
    info "hardware : /etc/nixos/hardware-configuration.nix"
else
    run "${SUDO[@]}" nixos-generate-config --show-hardware-config >"$host_dir/hardware-configuration.nix" ||
        warn "could not generate hardware-configuration.nix"
    info "hardware : nixos-generate-config"
fi

if [ ! -f "$host_dir/boot.nix" ] || grep -q "auto-generated by install.sh" "$host_dir/boot.nix"; then
    if [ -d /sys/firmware/efi ]; then
        cat >"$host_dir/boot.nix" <<'EOF'
# auto-generated by install.sh, overwritten on every run
{ ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 1;
}
EOF
        info "boot     : systemd-boot (EFI)"
    else
        disk=""
        root_src="$(findmnt -no SOURCE / 2>/dev/null || true)"
        if [ -n "$root_src" ]; then
            parent="$(lsblk -no PKNAME "$root_src" 2>/dev/null | head -1)"
            [ -n "$parent" ] && disk="/dev/$parent"
        fi
        if [ -z "$disk" ]; then
            disk="/dev/sda"
            warn "could not detect the boot disk, edit $host_dir/boot.nix"
        fi
        cat >"$host_dir/boot.nix" <<EOF
# auto-generated by install.sh, overwritten on every run
{ ... }:
{
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "$disk";
  boot.loader.grub.useOSProber = false;
  boot.loader.timeout = 1;
}
EOF
        info "boot     : GRUB on $disk"
    fi
fi

if [ "${#SUDO[@]}" -gt 0 ] && [ "$need_sudo" -eq 1 ]; then
    step "requesting administrator privileges"
    "${SUDO[@]}" -v || die "sudo failed"
fi

if [ "$do_gc" -eq 1 ]; then
    step "collecting garbage"
    info "removes old generations (pass --no-gc to keep them)"
    run "${SUDO[@]}" nix-collect-garbage -d
else
    step "keeping existing generations"
    info "skip garbage collection; pass --gc to collect"
fi

case "$action" in
build) RUN=() ;;
*) RUN=("${SUDO[@]}") ;;
esac

step "building and activating ($action)"
info "this can take a while"
: >"$LOG"

set +e
if [ "$verbose" -eq 1 ]; then
    "${RUN[@]}" env "PWNBOX_USER=$user" "PWNBOX_SYSTEM=$system" \
        nixos-rebuild "$action" --impure --flake "$FLAKE_DIR#$host" "${extra[@]}" 2>&1 | tee "$LOG"
    rc=${PIPESTATUS[0]}
else
    "${RUN[@]}" env "PWNBOX_USER=$user" "PWNBOX_SYSTEM=$system" \
        nixos-rebuild "$action" --impure --flake "$FLAKE_DIR#$host" "${extra[@]}" >"$LOG" 2>&1
    rc=$?
fi
set -e

if [ "$rc" -ne 0 ]; then
    warn "Build failed (exit $rc)"
    if [ "$verbose" -eq 0 ]; then
        printf '\n%s---- last lines of the log ----%s\n' "$C_DIM" "$C_RESET"
        tail -n 40 "$LOG" || true
        printf '%s--------------------------------%s\n\n' "$C_DIM" "$C_RESET"
        info "full log: $LOG  (rerun with --verbose)"
    fi
    exit "$rc"
fi

ok "Done ($action on '$host')"

step "preparing Obsidian vault"
vault="$home/Documents/Notes"
if [ ! -d "$vault/.obsidian" ]; then
    mkdir -p "$vault/.obsidian/plugins" "$vault/.obsidian/snippets"
    cat > "$vault/Welcome.md" <<'EOF'
# pwnbox notes

Obsidian vault, themed by pwnbox. The active palette (pywal or custom theme)
is applied as the `pwnbox` CSS snippet — switch it with `ALT + S`.

Installed community plugins: Dataview, Templater, Obsidian Git, Kanban,
Outliner, Style Settings, LaTeX Suite, QuickAdd.
EOF
    info "created $vault"
else
    info "vault already present: $vault"
fi

if [ "$action" != "build" ] && command -v systemctl >/dev/null 2>&1; then
    STEP_TOTAL=$((STEP_TOTAL + 1))
    step "restarting pwnbox styles server"
    if [ "$(id -un)" = "$user" ]; then
        run systemctl --user restart pwnbox-styles ||
            info "pwnbox-styles is not running yet (starts at next login)"
    else
        run runuser -u "$user" -- systemctl --user restart pwnbox-styles ||
            info "pwnbox-styles is not running yet (starts at next login)"
    fi
fi

info "reload: 'qs -n' for Quickshell, or log out/in for GNOME"
