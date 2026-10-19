{ ... }:
{
  imports = [
    ./options.nix
    ./locale.nix
    ./networking.nix
    ./nix.nix
    ./performance.nix
    ./security.nix
    ./sound.nix
    ./swap.nix
    ./users.nix
    ./vpn.nix
    ./virtualisation.nix
    ./branding.nix
    ./bootloader.nix
    ./desktop
    ./packages.nix
    ./hardening.nix
  ];

  system.stateVersion = "26.05";

  systemd.oomd.enable = false;
}
