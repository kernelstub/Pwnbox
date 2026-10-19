{
  config,
  lib,
  pkgs,
  ...
}:
lib.mkIf config.pwnbox.desktop.enable {
  fonts = {
    enableDefaultPackages = true;

    packages = with pkgs; [
      pwnbox.manrope

      ubuntu-classic
      spleen
      terminus_font_ttf
      fairfax-hd

      pwnbox.gnome-fonts

      nerd-fonts.iosevka
      nerd-fonts.jetbrains-mono
      nerd-fonts.meslo-lg
      nerd-fonts.fira-code
      nerd-fonts.symbols-only

      material-design-icons
      font-awesome
      noto-fonts-color-emoji

      iosevka
      jetbrains-mono
      inconsolata
      noto-fonts
      dejavu_fonts
      liberation_ttf
    ];

    fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [
          "Iosevka Nerd Font Mono"
          "JetBrainsMono Nerd Font Mono"
          "Noto Sans Mono"
        ];
        sansSerif = [
          "Manrope"
          "Noto Sans"
        ];
        serif = [ "Noto Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
