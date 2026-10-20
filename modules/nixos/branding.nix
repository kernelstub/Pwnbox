{
  config,
  lib,
  ...
}:
{
  options.pwnbox.branding = lib.mkOption {
    type = lib.types.bool;
    default = true;
    description = ''
      Rebrand the OS as pwnbox instead of NixOS.  Only cosmetic metadata is
      changed: `NAME` / `PRETTY_NAME` in `/etc/os-release` (what fastfetch,
      GNOME settings, etc. display) and the bootloader entry labels.
      `ID` stays `nixos` so tooling that detects NixOS keeps working, and
      nothing in the update path (`nixos-rebuild`, flake inputs, channels)
      reads these values, so updates are unaffected.
    '';
  };

  config = lib.mkIf config.pwnbox.branding {
    system.nixos.distroName = "pwnbox";
    system.nixos.label = "pwnbox";
  };
}
