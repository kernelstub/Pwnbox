#!/usr/bin/env bash
# Behavioural check of scripts/install.sh with stubbed system tools in a throwaway repo/home.
# Non-root: git-index cases. Root (e.g. a container with git+util-linux): also vault ownership cases.
set -euo pipefail
SRC="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)"
fail() { echo "FAIL: $*" >&2; exit 1; }
part="${PWNBOX_TEST_PART:-}"

# As root the account cases run useradd: only inside a disposable container (PWNBOX_TEST_CONTAINER=1).
if [ "$(id -u)" -eq 0 ] && [ -z "$part" ]; then
    [ "${PWNBOX_TEST_CONTAINER:-}" = 1 ] || { echo "install-behavior: skipped (root needs PWNBOX_TEST_CONTAINER=1 in a throwaway container)"; exit 0; }
    ! id pwnbox >/dev/null 2>&1 && [ ! -e /home/pwnbox ] || fail "pwnbox account/home already exists; not a clean container"
    useradd -m tester
    chmod 755 "$SRC" 2>/dev/null || true
    runuser -u tester -- env PWNBOX_TEST_PART=general bash "${BASH_SOURCE[0]}" || exit 1
    part=root
elif [ -z "$part" ]; then
    part=general
fi
T="$(mktemp -d)"
trap 'rm -rf "$T"' EXIT

mkstubs() { # $1=bindir $2=fake home or "" (getent prints nothing)
    mkdir -p "$1"
    printf '#!/bin/sh\nexit 0\n' >"$1/nix"
    printf '#!/bin/sh\nexit 0\n' >"$1/sudo"
    printf '#!/bin/sh\nexit 0\n' >"$1/systemctl"
    printf '#!/bin/sh\necho "fileSystems = {};"\n' >"$1/nixos-generate-config"
    printf '#!/bin/sh\n%s\nexit 0\n' "${REBUILD_HOOK:-:}" >"$1/nixos-rebuild"
    if [ -n "$2" ]; then
        printf '#!/bin/sh\n[ "$1" = passwd ] && echo "$2:x:0:0::%s:/bin/sh"\nexit 0\n' "$2" >"$1/getent"
    else
        printf '#!/bin/sh\nexit 0\n' >"$1/getent"
    fi
    chmod +x "$1"/*
}

mkrepo() { # $1=dir
    mkdir -p "$1/scripts" "$1/hosts/nixos"
    cp "$SRC/scripts/install.sh" "$1/scripts/"
    echo '{ networking.hostName = "nixos"; }' >"$1/hosts/nixos/default.nix"
    echo '{ }' >"$1/flake.nix"
    echo base >"$1/tracked"
    git -C "$1" init -q .
    git -C "$1" add -A
    git -C "$1" -c commit.gpgsign=false -c core.hooksPath=/dev/null -c user.email=t@t -c user.name=t commit -qm init --no-verify --no-gpg-sign
}

runinst() { # $1=repo $2=bindir; extra env via caller
    PATH="$2:$PATH" TMPDIR="$T" bash "$1/scripts/install.sh" "${3:-build}" --host h >"$T/out" 2>&1
}

if [ "$part" = general ]; then
# --- git index behaviour (any user)
me="$(id -un)"
R="$T/repo"; mkrepo "$R"; mkstubs "$T/bin" "$T/home"; mkdir -p "$T/home"
echo staged >>"$R/tracked"; git -C "$R" add tracked; echo unstaged >>"$R/tracked"
mkdir -p "$R/hosts/h"; echo keep >"$R/hosts/h/notes.txt"
before="$(git -C "$R" diff --cached tracked; git -C "$R" diff tracked)"
PWNBOX_USER="$me" runinst "$R" "$T/bin" || { cat "$T/out"; fail "install exited nonzero"; }
[ "$before" = "$(git -C "$R" diff --cached tracked; git -C "$R" diff tracked)" ] || fail "tracked/partial index changed"
git -C "$R" ls-files --error-unmatch hosts/h/default.nix hosts/h/hardware-configuration.nix hosts/h/boot.nix >/dev/null 2>&1 \
    || fail "generated configs not visible to git"
[ "$(git -C "$R" status --short hosts/h/notes.txt)" = "?? hosts/h/notes.txt" ] || fail "unrelated file touched"
[ "$(git -C "$R" show :tracked)" = "$(printf 'base\nstaged')" ] || fail "staged content lost"
[ ! -e "$T/home/Documents" ] || fail "build touched the vault"
PWNBOX_USER="$me" runinst "$R" "$T/bin" switch || { cat "$T/out"; fail "switch failed"; }
[ -f "$T/home/Documents/Notes/Welcome.md" ] || fail "vault not under resolved home"

# --- git failure is fatal
R2="$T/repo2"; mkrepo "$R2"; : >"$R2/.git/index.lock"
if PWNBOX_USER="$me" runinst "$R2" "$T/bin"; then fail "git failure ignored"; fi
grep -q "git add -N failed" "$T/out" || fail "no git failure message"
fi

# --- root: fresh account, no getent entry -> /home/pwnbox owned by pwnbox
if [ "$part" = root ]; then
    R3="$T/repo3"; mkrepo "$R3"
    mkstubs "$T/bin3" ""
    PWNBOX_USER=root runinst "$R3" "$T/bin3" || { cat "$T/out"; fail "root build failed"; }
    [ ! -e /home/pwnbox ] || fail "build created account/vault"
    REBUILD_HOOK='useradd -m pwnbox' mkstubs "$T/bin3" ""
    PWNBOX_USER=root runinst "$R3" "$T/bin3" switch || { cat "$T/out"; fail "root install failed"; }
    [ "$(stat -c %U "/home/pwnbox/Documents/Notes/Welcome.md")" = pwnbox ] || fail "vault not owned by pwnbox"
    [ "$(stat -c %U "/home/pwnbox/Documents/Notes/.obsidian")" = pwnbox ] || fail "obsidian dir not owned"
    [ ! -e /root/Documents/Notes ] || fail "root-owned vault created"
    # sudo-style activation: existing SUDO_USER target
    mkstubs "$T/bin3" ""
    SUDO_USER=tester runinst "$R3" "$T/bin3" switch || { cat "$T/out"; fail "SUDO_USER install failed"; }
    [ "$(stat -c %U /home/tester/Documents/Notes/Welcome.md)" = tester ] || fail "SUDO_USER vault not owned by tester"
fi
echo "install-behavior: ok"
