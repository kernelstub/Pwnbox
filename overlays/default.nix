final: prev: {
  signal-desktop = final.callPackage ../pkgs/signal-desktop.nix {
    signal-desktop = prev.signal-desktop;
  };

  exodus = final.callPackage ../pkgs/exodus.nix {
    exodus = prev.exodus;
  };

  kitty = prev.kitty.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace kitty/shaders.c \
        --replace-fail 'w->live_resize.num_of_resize_events > 1' '0'
    '';
  });

  pwnbox = {
    dotfiles = final.callPackage ../pkgs/dotfiles.nix { };
    manrope = final.callPackage ../pkgs/manrope.nix { };
    colloid-cursors = final.callPackage ../pkgs/colloid-cursors.nix { };
    gnome-fonts = final.callPackage ../pkgs/gnome-fonts.nix { };

    colloid-dark-grey = final.callPackage ../pkgs/colloid-dark-grey.nix {
      accent = "#454545";
    };

    tg-config = final.callPackage ../pkgs/tg-config.nix { };

    sharphound = final.callPackage ../pkgs/sharphound.nix { };

    impacket-tools = final.callPackage ../pkgs/impacket-tools.nix { };

    stremio-enhanced = final.callPackage ../pkgs/stremio-enhanced.nix {
      extraFonts = [
        final.pwnbox.manrope
        final.pwnbox.gnome-fonts
      ];
    };

    ida = final.callPackage ../pkgs/ida-fhs.nix { };

    spicetify-marketplace = final.callPackage ../pkgs/spicetify-marketplace.nix { };

    obsidian-plugins = final.callPackage ../pkgs/obsidian-plugins.nix { };

    grub-theme = final.callPackage ../pkgs/pwnbox-grub-theme.nix { };
  };
}
