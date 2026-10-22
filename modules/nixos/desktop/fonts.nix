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
      ioskeley-mono.normal
      ioskeley-mono.normal-NF
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
          "IoskeleyMono Nerd Font"
          "Noto Sans Mono"
        ];
        sansSerif = [
          "IoskeleyMono Nerd Font"
          "Noto Sans"
        ];
        serif = [ "Noto Serif" ];
        emoji = [ "Noto Color Emoji" ];
      };
    };
  };
}
