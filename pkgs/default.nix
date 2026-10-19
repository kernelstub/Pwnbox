{ pkgs }:
{
  dotfiles = pkgs.callPackage ./dotfiles.nix { };
  manrope = pkgs.callPackage ./manrope.nix { };
  colloid-cursors = pkgs.callPackage ./colloid-cursors.nix { };
  gnome-fonts = pkgs.callPackage ./gnome-fonts.nix { };
  tg-config = pkgs.callPackage ./tg-config.nix { };
  stremio-enhanced = pkgs.callPackage ./stremio-enhanced.nix { };
  spicetify-marketplace = pkgs.callPackage ./spicetify-marketplace.nix { };
  obsidian-plugins = pkgs.callPackage ./obsidian-plugins.nix { };
  ida = pkgs.callPackage ./ida-fhs.nix { };
  grub-theme = pkgs.callPackage ./pwnbox-grub-theme.nix { };
}
