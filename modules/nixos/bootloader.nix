{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.boot.loader.grub.enable {
  boot.loader.grub.theme = "${pkgs.pwnbox.grub-theme}";
}
