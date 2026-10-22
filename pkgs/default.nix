{ pkgs }:
{
  dotfiles = pkgs.callPackage ./desktop/dotfiles.nix { };
  manrope = pkgs.callPackage ./desktop/manrope.nix { };
  colloid-cursors = pkgs.callPackage ./desktop/colloid-cursors.nix { };
  gnome-fonts = pkgs.callPackage ./desktop/gnome-fonts.nix { };
  tg-config = pkgs.callPackage ./apps/messaging/tg-config.nix { };
  stremio-enhanced = pkgs.callPackage ./apps/media/stremio-enhanced.nix { };
  spicetify-marketplace = pkgs.callPackage ./apps/media/spicetify-marketplace.nix { };
  obsidian-plugins = pkgs.callPackage ./apps/notes/obsidian-plugins.nix { };
  ida = pkgs.callPackage ./security/ida-fhs.nix { };
  grub-theme = pkgs.callPackage ./desktop/pwnbox-grub-theme.nix { };
}
