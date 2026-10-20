#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
FLAKE_DIR="$(cd -- "$SCRIPT_DIR/.." && pwd)"
LOG="${TMPDIR:-/tmp}/pwnbox-install.log"
RULE_WIDTH=78

C_RESET=""
C_BOLD=""
C_DIM=""
C_BLUE=""
C_CYAN=""
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
    printf '    %s./scripts/install.sh [ACTION] [OPTIONS] [-- EXTRA...]%s\n' "${C_DIM:-}" "${C_RESET:-}"
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
    printf '    %s./scripts/install.sh%s\n' "${C_DIM:-}" "${C_RESET:-}"
    printf '    %s./scripts/install.sh build%s\n' "${C_DIM:-}" "${C_RESET:-}"
    printf '    %s./scripts/install.sh test -H nixos%s\n' "${C_DIM:-}" "${C_RESET:-}"
    printf '    %s./scripts/install.sh switch --verbose%s\n' "${C_DIM:-}" "${C_RESET:-}"
    printf '    %s./scripts/install.sh switch -- --show-trace%s\n' "${C_DIM:-}" "${C_RESET:-}"
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
            echo "scripts/install.sh: --host needs a value" >&2
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
        echo "scripts/install.sh: unknown argument '$1'" >&2
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
    C_CYAN=$'\033[36m'
    C_GREEN=$'\033[32m'
    C_YELLOW=$'\033[33m'
    C_RED=$'\033[31m'
else
    C_RESET=""
    C_BOLD=""
    C_DIM=""
    C_BLUE=""
    C_CYAN=""
    C_GREEN=""
    C_YELLOW=""
    C_RED=""
fi

rule() {
    local char="${1:-─}" i
    printf '%s' "$C_DIM"
    for ((i = 0; i < RULE_WIDTH; i++)); do
        printf '%s' "$char"
    done
    printf '%s\n' "$C_RESET"
}

elapsed_text() {
    local elapsed=$((SECONDS - START_SECONDS))
    printf '%02d:%02d' "$((elapsed / 60))" "$((elapsed % 60))"
}

state_color() {
    case "$1" in
    pass) printf '%s' "$C_GREEN" ;;
    run) printf '%s' "$C_CYAN" ;;
    skip | warn) printf '%s' "$C_YELLOW" ;;
    fail) printf '%s' "$C_RED" ;;
    *) printf '%s' "$C_DIM" ;;
    esac
}

row() {
    local label=$1 result=$2 detail=$3
    printf '  %-22s %s%-8s%s %s\n' \
        "$label" "$(state_color "$result")" "$result" "$C_RESET" "$detail"
}

preflight_row() {
    row "$1" "$2" "$3"
    case "$2" in
    fail) PREFLIGHT_FAILED=1 ;;
    warn) PREFLIGHT_WARNED=1 ;;
    esac
}

exec_row() {
    row "$1" "$2" "$3"
    case "$2" in
    warn) WARNINGS=$((WARNINGS + 1)) ;;
    esac
}

info() { printf '        %s%s%s\n' "$C_DIM" "$*" "$C_RESET"; }
warn() { printf '  %sWARN%s  %s\n' "$C_YELLOW$C_BOLD" "$C_RESET" "$*" >&2; }
die() {
    printf '\n  %sFAIL%s  %s\n' "$C_RED$C_BOLD" "$C_RESET" "$*" >&2
    exit 1
}

run() {
    if [ "$verbose" -eq 1 ]; then
        "$@"
    else
        "$@" >/dev/null 2>&1
    fi
}

run_to_file() {
    local target=$1
    shift
    if [ "$verbose" -eq 1 ]; then
        "$@" >"$target"
    else
        "$@" >"$target" 2>/dev/null
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

show_banner() {
    printf '%s\n' "$C_BLUE$C_BOLD"
    banner
    printf '%s\n' "$C_RESET"
}

help_screen() {
    show_banner
    printf '  %sNixOS workstation provisioning%s\n' "$C_DIM" "$C_RESET"
    usage_text
}

preflight_header() {
    printf '%sPWNBOX PREFLIGHT INSPECTION%s\n' "$C_BOLD" "$C_RESET"
    printf '  %-14s %s\n' "Target" "$host"
    printf '  %-14s %s\n' "Flake" "$short_flake"
    rule
    printf '  %-22s %-8s %s\n' "CHECK" "RESULT" "DETAIL"
    rule
}

execution_header() {
    printf '\n%sPWNBOX EXECUTION%s\n' "$C_BOLD" "$C_RESET"
    rule
    printf '  %-22s %-8s %s\n' "PHASE" "RESULT" "DETAIL"
    rule
}

read_generation() {
    local target
    current_generation=""
    if [ -L /nix/var/nix/profiles/system ]; then
        target="$(readlink /nix/var/nix/profiles/system 2>/dev/null || true)"
        case "$target" in
        system-*-link)
            current_generation="${target#system-}"
            current_generation="${current_generation%-link}"
            ;;
        esac
    fi
    case "$current_generation" in
    "" | *[!0-9]*)
        next_generation=""
        generation_detail="next"
        ;;
    *)
        next_generation=$((current_generation + 1))
        generation_detail="$current_generation -> $next_generation"
        ;;
    esac
}

read_boot_plan() {
    boot_mode=""
    boot_disk=""
    boot_detail=""
    boot_warn=0
    if [ -f "$host_dir/boot.nix" ] && ! grep -q "auto-generated by install.sh" "$host_dir/boot.nix"; then
        boot_mode="existing"
        if grep -Eq 'boot\.loader\.systemd-boot\.enable[[:space:]]*=[[:space:]]*true' "$host_dir/boot.nix" 2>/dev/null; then
            boot_detail="systemd-boot (UEFI)"
        elif grep -Eq 'boot\.loader\.grub\.enable[[:space:]]*=[[:space:]]*true' "$host_dir/boot.nix" 2>/dev/null; then
            boot_detail="GRUB (host config)"
        else
            boot_detail="host boot.nix"
        fi
    elif [ -d /sys/firmware/efi ]; then
        boot_mode="efi"
        boot_detail="systemd-boot (UEFI)"
    else
        boot_mode="grub"
        root_src="$(findmnt -no SOURCE / 2>/dev/null || true)"
        if [ -n "$root_src" ]; then
            parent="$(lsblk -no PKNAME "$root_src" 2>/dev/null | head -1 || true)"
            [ -n "$parent" ] && boot_disk="/dev/$parent"
        fi
        if [ -z "$boot_disk" ]; then
            boot_disk="/dev/sda"
            boot_detail="GRUB on /dev/sda (fallback)"
            boot_warn=1
        else
            boot_detail="GRUB on $boot_disk"
        fi
    fi
}

if [ "$want_help" -eq 1 ]; then
    help_screen
    exit 0
fi

if [ -t 1 ]; then
    clear
fi

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
    printf '\n'
elif [ -t 1 ]; then
    show_banner
fi

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

host_dir="$FLAKE_DIR/hosts/$host"
need_sudo=0
[ "$do_gc" -eq 1 ] && need_sudo=1
[ "$action" != "build" ] && need_sudo=1

START_SECONDS=$SECONDS
PREFLIGHT_FAILED=0
PREFLIGHT_WARNED=0
WARNINGS=0

short_flake="$FLAKE_DIR"
if [ -n "$home" ] && [ "${FLAKE_DIR#"$home"}" != "$FLAKE_DIR" ]; then
    short_flake="~${FLAKE_DIR#"$home"}"
fi

read_generation
read_boot_plan

preflight_header

if [ -f "$FLAKE_DIR/flake.nix" ]; then
    preflight_row "flake.nix" "pass" "readable"
else
    preflight_row "flake.nix" "fail" "missing"
fi

if command -v nixos-rebuild >/dev/null 2>&1; then
    preflight_row "nixos-rebuild" "pass" "found in PATH"
else
    preflight_row "nixos-rebuild" "fail" "not found in PATH"
fi

if [ "${#SUDO[@]}" -eq 0 ]; then
    preflight_row "sudo" "pass" "running as root"
elif [ "$need_sudo" -eq 0 ]; then
    preflight_row "sudo" "pass" "not required for $action"
elif command -v sudo >/dev/null 2>&1; then
    if sudo -n true >/dev/null 2>&1; then
        preflight_row "sudo" "pass" "credentials cached"
    else
        preflight_row "sudo" "pass" "prompt required"
    fi
else
    preflight_row "sudo" "fail" "sudo not found"
fi

if [ -f "$host_dir/default.nix" ]; then
    preflight_row "host config" "pass" "hosts/$host/default.nix"
elif [ -f "$FLAKE_DIR/hosts/nixos/default.nix" ]; then
    preflight_row "host config" "pass" "will create hosts/$host/default.nix"
else
    preflight_row "host config" "fail" "template missing"
fi

if [ -f /etc/nixos/hardware-configuration.nix ] &&
    grep -q "fileSystems" /etc/nixos/hardware-configuration.nix; then
    preflight_row "hardware config" "pass" "/etc/nixos/hardware-configuration.nix"
elif command -v nixos-generate-config >/dev/null 2>&1; then
    preflight_row "hardware config" "pass" "generate with nixos-generate-config"
else
    preflight_row "hardware config" "fail" "unavailable"
fi

if [ "$boot_warn" -eq 1 ]; then
    preflight_row "bootloader" "warn" "$boot_detail"
else
    preflight_row "bootloader" "pass" "$boot_detail"
fi

store_result="pass"
if [ -w /nix/store ]; then
    store_detail="writable"
elif command -v nix >/dev/null 2>&1 && nix store ping >/dev/null 2>&1; then
    store_detail="writable via daemon"
elif command -v nix-store >/dev/null 2>&1 && nix-store --version >/dev/null 2>&1; then
    store_detail="nix-store available"
else
    store_result="fail"
    store_detail="not accessible"
fi
preflight_row "nix store" "$store_result" "$store_detail"

network_ok=0
if command -v getent >/dev/null 2>&1; then
    if command -v timeout >/dev/null 2>&1; then
        if timeout 3 getent hosts cache.nixos.org >/dev/null 2>&1; then
            network_ok=1
        fi
    elif getent hosts cache.nixos.org >/dev/null 2>&1; then
        network_ok=1
    fi
fi
if [ "$network_ok" -eq 1 ]; then
    preflight_row "network" "pass" "cache.nixos.org reachable"
else
    preflight_row "network" "warn" "unreachable (cached inputs may work)"
fi

rule

if [ "$PREFLIGHT_FAILED" -ne 0 ]; then
    die "preflight inspection found blocking issues"
fi

if [ -n "$next_generation" ]; then
    if [ "$PREFLIGHT_WARNED" -ne 0 ]; then
        printf '  Ready to build generation %s (with warnings).\n' "$next_generation"
    else
        printf '  Ready to build generation %s.\n' "$next_generation"
    fi
elif [ "$PREFLIGHT_WARNED" -ne 0 ]; then
    printf '  Ready to build the next generation (with warnings).\n'
else
    printf '  Ready to build the next generation.\n'
fi

execution_header

migrated=0
for _c in kitty rofi fuzzel alacritty zathura; do
    _p="$home/.config/$_c"
    if [ -L "$_p" ]; then
        case "$(readlink "$_p")" in
        /nix/store/*home-manager-files/*)
            run rm -f "$_p"
            migrated=$((migrated + 1))
            ;;
        esac
    fi
done
if [ "$migrated" -eq 1 ]; then
    exec_row "config links" "pass" "1 home-manager link fixed"
elif [ "$migrated" -gt 1 ]; then
    exec_row "config links" "pass" "$migrated home-manager links fixed"
fi

if [ ! -f "$host_dir/default.nix" ]; then
    exec_row "host configuration" "run" "creating hosts/$host"
    if ! mkdir -p "$host_dir"; then
        exec_row "host configuration" "fail" "could not create directory"
        die "could not create $host_dir"
    fi
    if ! cp "$FLAKE_DIR/hosts/nixos/default.nix" "$host_dir/default.nix"; then
        exec_row "host configuration" "fail" "could not copy template"
        die "could not create $host_dir/default.nix"
    fi
    sed -i "s/hostName = \"nixos\"/hostName = \"$host\"/" "$host_dir/default.nix" 2>/dev/null || true
    sed -i 's/mainMonitor = "[^"]*"/mainMonitor = ""/; s/leftMonitor = "[^"]*"/leftMonitor = ""/' \
        "$host_dir/default.nix" 2>/dev/null || true

    tz="$(timedatectl show -p Timezone --value 2>/dev/null || true)"
    detail="hosts/$host (created)"
    if [ -n "$tz" ]; then
        sed -i "s#timeZone = \"[^\"]*\"#timeZone = \"$tz\"#" "$host_dir/default.nix" 2>/dev/null || true
        detail="hosts/$host (created, $tz)"
    fi
    exec_row "host configuration" "pass" "$detail"
else
    exec_row "host configuration" "pass" "hosts/$host/default.nix"
fi

exec_row "hardware and boot" "run" "refreshing machine configuration"

hardware_warn=0
if [ -f /etc/nixos/hardware-configuration.nix ] &&
    grep -q "fileSystems" /etc/nixos/hardware-configuration.nix; then
    if cp /etc/nixos/hardware-configuration.nix "$host_dir/hardware-configuration.nix"; then
        hardware_note="hardware copied"
    else
        hardware_note="hardware warning"
        hardware_warn=1
        warn "could not copy hardware-configuration.nix"
    fi
else
    if run_to_file "$host_dir/hardware-configuration.nix" \
        nixos-generate-config --show-hardware-config; then
        hardware_note="hardware generated"
    elif [ "${#SUDO[@]}" -gt 0 ] &&
        run_to_file "$host_dir/hardware-configuration.nix" \
            "${SUDO[@]}" nixos-generate-config --show-hardware-config; then
        hardware_note="hardware generated"
    else
        hardware_note="hardware warning"
        hardware_warn=1
        warn "could not generate hardware-configuration.nix"
    fi
fi

case "$boot_mode" in
existing)
    boot_note="$boot_detail"
    ;;
efi)
    cat >"$host_dir/boot.nix" <<'EOF'
# auto-generated by install.sh, overwritten on every run
{ ... }:
{
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.loader.timeout = 1;
}
EOF
    boot_note="systemd-boot (UEFI)"
    ;;
grub)
    if [ "$boot_warn" -eq 1 ]; then
        warn "could not detect the boot disk, edit $host_dir/boot.nix"
    fi
    cat >"$host_dir/boot.nix" <<EOF
# auto-generated by install.sh, overwritten on every run
{ ... }:
{
  boot.loader.grub.enable = true;
  boot.loader.grub.device = "$boot_disk";
  boot.loader.grub.useOSProber = false;
  boot.loader.timeout = 1;
}
EOF
    boot_note="GRUB on $boot_disk"
    ;;
esac

if [ "$hardware_warn" -eq 1 ] || [ "$boot_warn" -eq 1 ]; then
    exec_row "hardware and boot" "warn" "$hardware_note; $boot_note"
else
    exec_row "hardware and boot" "pass" "$hardware_note; $boot_note"
fi

if [ "${#SUDO[@]}" -eq 0 ]; then
    exec_row "privilege" "pass" "running as root"
elif [ "$need_sudo" -eq 0 ]; then
    exec_row "privilege" "skip" "not required for $action"
else
    exec_row "privilege" "run" "requesting administrator credentials"
    if "${SUDO[@]}" -v; then
        exec_row "privilege" "pass" "credentials cached"
    else
        exec_row "privilege" "fail" "sudo failed"
        die "administrator credentials were not provided"
    fi
fi

if [ "$do_gc" -eq 1 ]; then
    exec_row "generation policy" "run" "collecting garbage"
    if run "${SUDO[@]}" nix-collect-garbage -d; then
        exec_row "generation policy" "pass" "old generations collected"
    else
        exec_row "generation policy" "fail" "garbage collection failed"
        die "nix-collect-garbage failed"
    fi
else
    exec_row "generation policy" "skip" "keeping existing generations"
fi

case "$action" in
build) RUN=() ;;
*) RUN=("${SUDO[@]}") ;;
esac

exec_row "build and activate" "run" "nixos-rebuild $action"
if ! : >"$LOG"; then
    exec_row "build and activate" "fail" "could not open log"
    die "could not write $LOG"
fi
info "this can take a while; log: $LOG"

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
    exec_row "build and activate" "fail" "exit $rc"
    warn "build failed; see $LOG"
    if [ "$verbose" -eq 0 ]; then
        printf '\n%s---- last lines of the log ----%s\n' "$C_DIM" "$C_RESET"
        tail -n 40 "$LOG" || true
        printf '%s--------------------------------%s\n' "$C_DIM" "$C_RESET"
        info "full log: $LOG  (rerun with --verbose)"
    fi
    printf '\n'
    printf '  %-12s %s%s%s\n' "Result" "$C_RED$C_BOLD" "failed at build (exit $rc)" "$C_RESET"
    printf '  %-12s %s\n' "Generation" "$generation_detail"
    printf '  %-12s %s\n' "Elapsed" "$(elapsed_text)"
    printf '  %-12s %s\n' "Log" "$LOG"
    exit "$rc"
fi

case "$action" in
switch) action_note="generation activated" ;;
test) action_note="activated for this boot" ;;
boot) action_note="generation set for next boot" ;;
build) action_note="generation built" ;;
dry-activate) action_note="dry activation complete" ;;
*) action_note="$action completed" ;;
esac
exec_row "build and activate" "pass" "$action_note"

exec_row "verify" "run" "vault and desktop services"
vault="$home/Documents/Notes"
if [ ! -d "$vault/.obsidian" ]; then
    if ! mkdir -p "$vault/.obsidian/plugins" "$vault/.obsidian/snippets"; then
        exec_row "verify" "fail" "could not create vault"
        die "could not create $vault"
    fi
    if ! cat > "$vault/Welcome.md" <<'EOF'
# pwnbox notes

Obsidian vault, themed by pwnbox. The active palette (pywal or custom theme)
is applied as the `pwnbox` CSS snippet — switch it with `ALT + S`.

Installed community plugins: Dataview, Templater, Obsidian Git, Kanban,
Outliner, Style Settings, LaTeX Suite, QuickAdd.
EOF
    then
        exec_row "verify" "fail" "could not write vault"
        die "could not write $vault/Welcome.md"
    fi
    info "vault created: $vault"
else
    info "vault present: $vault"
fi

styles_note="service reload skipped"
case "$action" in
switch | test)
    if command -v systemctl >/dev/null 2>&1; then
        if [ "$(id -un)" = "$user" ]; then
            if run systemctl --user restart pwnbox-styles; then
                styles_note="styles restarted"
            else
                styles_note="styles pending"
                info "pwnbox-styles is not running yet (starts at next login)"
            fi
        else
            if run runuser -u "$user" -- systemctl --user restart pwnbox-styles; then
                styles_note="styles restarted"
            else
                styles_note="styles pending"
                info "pwnbox-styles is not running yet (starts at next login)"
            fi
        fi
    fi
    ;;
esac

exec_row "verify" "pass" "vault ready; $styles_note"

case "$action" in
switch | test) next_note="log out/in for GNOME, or run: qs -n" ;;
boot) next_note="reboot to use the new generation" ;;
build) next_note="run with switch or test to activate" ;;
dry-activate) next_note="review planned changes; no system activation" ;;
*) next_note="review the log at $LOG" ;;
esac

if [ "$WARNINGS" -eq 0 ]; then
    result_note="success ($action on $host)"
    result_color="$C_GREEN$C_BOLD"
else
    result_note="success with warnings ($action on $host)"
    result_color="$C_YELLOW$C_BOLD"
fi

printf '\n'
rule
printf '  %-12s %s%s%s\n' "Result" "$result_color" "$result_note" "$C_RESET"
printf '  %-12s %s\n' "Generation" "$generation_detail"
printf '  %-12s %s\n' "Elapsed" "$(elapsed_text)"
printf '  %-12s %s\n' "Log" "$LOG"
printf '  %-12s %s\n' "Next" "$next_note"
