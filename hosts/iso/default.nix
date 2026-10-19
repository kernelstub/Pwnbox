# pwnbox live desktop ISO
#
# Full Hyprland + GNOME desktop with the pentest toolset, running from a
# squashfs root with tmpfs overlays — everything lives in RAM and evaporates
# on reboot (zero-trace by design).
#
# Built as: nix build .#images.<system>.live
{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
{
  imports = [
    # Bare ISO module — NOT installation-cd-base.nix. The installer profile
    # pulls in profiles/installation-device.nix, which clashes with pwnbox's
    # hardening (root password options and security.sudo vs sudo-rs).
    (inputs.nixpkgs + "/nixos/modules/installer/cd-dvd/iso-image.nix")
  ];

  # Autodetect hardware on whatever machine this boots on.
  hardware.enableAllHardware = true;
  # Note: nixpkgs.hostPlatform is set by mkImage in flake.nix (per-arch), the
  # same line nixos-generate-config writes into hardware-configuration.nix.

  # Safety net for non-x86_64 images: some packages drag in x86_64-only
  # dependencies deep in their closure (e.g. apktool -> aapt). Without this,
  # evaluation refuses those packages outright; with it, they are included
  # (and may be runtime-broken on ARM). Top-level x86_64-only packages are
  # still filtered from the toolset via lib.meta.availableOn.
  nixpkgs.config.allowUnsupportedSystem = true;

  pwnbox = {
    username = "pwnbox";
    fullName = "pwnbox";
    hostName = "pwnbox-live";
    timeZone = "UTC";

    desktop = {
      enable = true;
      # Unknown display on unknown hardware.
      resolution = "highres";
    };

    # Keep the ISO lean(ish).
    vpn.mullvad = false;
    virtualisation.docker = false;
    virtualisation.libvirtd = false;
    virtualisation.wireshark = false;

    packages = {
      # The full pentest toolset. Flip to false for a much smaller ISO.
      hacking = true;
      gaming = false;
      creative = false;
    };
  };

  # Set at boot by the activation script (stage-2 runs it on live media).
  # Change with `passwd` after login.
  users.users.pwnbox.initialPassword = "pwnbox";

  # hardening.nix disables autologin; the live ISO needs it back.
  # ly (the pwnbox display manager) supports the generic autoLogin option.
  services.displayManager.autoLogin = {
    enable = lib.mkForce true;
    user = "pwnbox";
  };

  # hardening.nix sets kernel params tuned for one known machine
  # (iommu=force, amd_iommu=on, efi=disable_early_pci_dma, oops=panic panic=10).
  # For a portable live ISO those can stop booting on other hardware, so
  # replace them wholesale — keeping only what the ISO itself needs
  # (the iso-image module adds root=LABEL for the scripted initrd).
  boot.kernelParams = lib.mkForce (
    [
      "quiet"
      "loglevel=0"
    ]
    ++ lib.optionals (!config.boot.initrd.systemd.enable) [
      "boot.shell_on_fail"
      "root=LABEL=${config.isoImage.volumeID}"
    ]
  );

  isoImage = {
    volumeID = "PWNBOXLIVE";
    makeEfiBootable = true;
    makeUsbBootable = true;
    squashfsCompression = "zstd -Xcompression-level 19";
  };

  # Output filename: result/iso/pwnbox-live.iso
  # (isoImage.isoName was renamed to image.baseName in nixpkgs 25.05)
  image.baseName = lib.mkForce "pwnbox-live";

  system.stateVersion = "26.05";
}
