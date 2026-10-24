# ISOs

pwnbox ships two kinds of bootable images per architecture, built straight
from the flake with `./scripts/iso.sh` (or plain `nix build`):

| Image | Flake output | What you get |
| --- | --- | --- |
| **live** | `.#images.<system>.live` | The full pwnbox desktop (Hyprland + GNOME) with the pentest toolset. Boots from the stick, runs entirely in RAM, leaves no trace. |
| **installer** | `.#images.<system>.installer` | A stock NixOS installer that carries this flake at `/pwnbox`, read-only, so you can install pwnbox onto a disk. |

## Build

Requirements: Nix with flakes enabled, and network access for the first
fetch. Files must be tracked by git (the flake ignores untracked files —
`scripts/iso.sh` warns about them).

```bash
./scripts/iso.sh                      # live + installer for this machine
./scripts/iso.sh live                 # just the live ISO
./scripts/iso.sh installer            # just the installer ISO
./scripts/iso.sh -n                   # evaluate configs only, do not build
```

Finished images land in `iso/pwnbox-<image>-<arch>.iso`, with size and
sha256 printed for each. Run `./scripts/iso.sh --help` for all options
(remote builders, custom output dir, writing straight to a USB stick, …).

The same images can be built directly with nix:

```bash
nix build .#images.x86_64-linux.live          # → result/iso/pwnbox-live.iso
nix build .#images.x86_64-linux.installer     # → result/iso/pwnbox-installer.iso
```

### Architectures

| System | Live ISO | Installer ISO | Notes |
| --- | --- | --- | --- |
| `x86_64-linux` | BIOS + UEFI | yes | Builds natively; this covers every PC and laptop. |
| `aarch64-linux` | UEFI only | UEFI only | Needs an ARM builder (`--builders 'ssh-ng://root@pi aarch64-linux - 8'`) or binfmt emulation (slow). Does **not** boot on Raspberry Pi-style boards without UEFI. |

Building for a foreign architecture:

```bash
./scripts/iso.sh live -a aarch64-linux --builders 'ssh-ng://root@pi aarch64-linux - 8'
```

## Live ISO

### Credentials

| | |
| --- | --- |
| User | `pwnbox` |
| Password | `pwnbox` — change it after login with `passwd` |
| Root | locked (sudo via the `pwnbox` account) |
| Time zone | UTC |
| Session | Hyprland (autologin); GNOME available as a second session |

### Behaviour

- **Zero persistence.** `/`, `/home` and the store overlay are RAM-backed;
  a reboot resets everything to the image. Nothing is ever written to the
  stick — this is the point.
- **Hardware.** All firmware is bundled, so wireless, Bluetooth and GPU
  firmware work out of the box on almost any machine.
- **NVIDIA.** The live image uses the open-source `nouveau` driver (no
  proprietary driver on the ISO). Desktop use works; install to disk for
  CUDA or the proprietary driver.
- **IDA.** IDA itself is proprietary and never included. The FHS wrapper is
  on the x86_64 image — point it at your own installation with
  `PWNBOX_IDA_HOME` (see [Apps](../usage/apps.md#ida-free--pro)).
- **RAM.** The squashfs store is loop-mounted from the stick, but Hyprland +
  GNOME + the toolset are happiest with 8 GB+; 4 GB will boot but swap hard
  (zram).

### Booting

Flash with `dd`, or copy the ISO onto a [Ventoy](https://www.ventoy.net) stick
(a plain `.iso` file in the data partition; the live ISO is far larger than 4 GB,
so use Ventoy's default exFAT data partition, never FAT32):

```bash
sudo dd if=iso/pwnbox-live-x86_64-linux.iso of=/dev/sdX bs=4M conv=fsync status=progress
```

On Ventoy, press Enter on the ISO and pick **Boot in normal mode**. Do **not**
use *Boot in grub2 mode*: Ventoy's patched GRUB renames the kernel parameter
`init=` to `vtinit=`, and the NixOS initrd (`initrd-find-nixos-closure`) only
reads `init=`, so boot stops in the emergency shell with "No init= parameter on
the kernel command line". This affects NixOS images that use this systemd initrd
and is open upstream: [ventoy/Ventoy#2689](https://github.com/ventoy/Ventoy/issues/2689).

If the machine refuses to boot it, disable Secure Boot in the firmware — the
ISO is not Microsoft-signed.

The live session logs in by itself through Ly's autologin and starts the
`hyprland-uwsm` session (Hyprland under `uwsm`). `hosts/iso` selects it
explicitly: Ly matches the session name `hyprland` against two session files, so
it can pick the uwsm one, and that session only starts when
`programs.hyprland.withUWSM` is on.

### Testing that an image boots

Checksums and `xorriso` header dumps do not show that an image boots. Boot it
in a VM, BIOS and UEFI (OVMF), and look at the screen:

```bash
cp /usr/share/OVMF/OVMF_VARS_4M.fd OVMF_VARS.fd      # firmware paths differ per distro
qemu-system-x86_64 -m 8G -enable-kvm -cdrom iso/pwnbox-live-x86_64-linux.iso
qemu-system-x86_64 -m 8G -enable-kvm -cdrom iso/pwnbox-live-x86_64-linux.iso \
  -drive if=pflash,format=raw,readonly=on,file=/usr/share/OVMF/OVMF_CODE_4M.fd \
  -drive if=pflash,format=raw,file=OVMF_VARS.fd
```

To test the Ventoy path, install Ventoy onto a disk image (an empty file made
with `truncate`, attached with `losetup -P` and passed to `Ventoy2Disk.sh -I`),
copy the ISO onto its exFAT partition, and boot the file as a USB disk with
`-drive file=stick.img,format=raw,if=none,id=u,snapshot=on -device qemu-xhci
-device usb-storage,drive=u,bootindex=0`, once with and once without the OVMF
drives. In Ventoy's menu pick the ISO, then **Boot in normal mode**.

## Installer ISO

Boot it, partition the disk, then install from the embedded flake:

```bash
mkfs.ext4 /dev/nvme0n1p2            # after partitioning (gdisk)
mount /dev/nvme0n1p2 /mnt
mkdir -p /mnt/root
cp -rL /pwnbox /mnt/root/pwnbox                      # /pwnbox is a read-only store symlink
chmod -R u+w /mnt/root/pwnbox                        # keeps exec bits, makes it writable

nixos-generate-config --root /mnt
cp /mnt/etc/nixos/hardware-configuration.nix /mnt/root/pwnbox/hosts/nixos/

nixos-install --flake '/mnt/root/pwnbox#nixos'
```

On aarch64, tell the flake which system you want (it defaults to
`x86_64-linux`):

```bash
PWNBOX_SYSTEM=aarch64-linux nixos-install --impure --flake '/mnt/root/pwnbox#nixos'
```

After the first boot, run `./scripts/install.sh switch` from `/root/pwnbox`
to let it create the host-specific config, or continue with `nixos-rebuild
--flake .#nixos`.
