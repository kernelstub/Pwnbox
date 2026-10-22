final: prev: {
  signal-desktop = final.callPackage ../pkgs/apps/messaging/signal-desktop.nix {
    signal-desktop = prev.signal-desktop;
  };

  element-desktop = final.callPackage ../pkgs/apps/messaging/element-desktop.nix {
    element-desktop = prev.element-desktop;
  };

  wire-desktop = final.callPackage ../pkgs/apps/messaging/wire-desktop.nix {
    wire-desktop = prev.wire-desktop;
  };

  simplex-chat-desktop = final.callPackage ../pkgs/apps/messaging/simplex-chat-desktop.nix {
    simplex-chat-desktop = prev.simplex-chat-desktop;
    appimageTools = prev.appimageTools;
  };

  exodus = final.callPackage ../pkgs/apps/wallets/exodus.nix {
    exodus = prev.exodus;
  };

  kitty = prev.kitty.overrideAttrs (old: {
    postPatch = (old.postPatch or "") + ''
      substituteInPlace kitty/shaders.c \
        --replace-fail 'w->live_resize.num_of_resize_events > 1' '0'
    '';
  });

  pwnbox = {
    dotfiles = final.callPackage ../pkgs/desktop/dotfiles.nix { };
    manrope = final.callPackage ../pkgs/desktop/manrope.nix { };
    colloid-cursors = final.callPackage ../pkgs/desktop/colloid-cursors.nix { };
    gnome-fonts = final.callPackage ../pkgs/desktop/gnome-fonts.nix { };

    colloid-dark-grey = final.callPackage ../pkgs/desktop/colloid-dark-grey.nix {
      accent = "#454545";
    };

    tg-config = final.callPackage ../pkgs/apps/messaging/tg-config.nix { };

    sharphound = final.callPackage ../pkgs/security/sharphound.nix { };

    impacket-tools = final.callPackage ../pkgs/security/impacket-tools.nix { };

    stremio-enhanced = final.callPackage ../pkgs/apps/media/stremio-enhanced.nix {
      extraFonts = [
        final.pwnbox.manrope
        final.pwnbox.gnome-fonts
      ];
    };

    ida = final.callPackage ../pkgs/security/ida-fhs.nix { };

    spicetify-marketplace = final.callPackage ../pkgs/apps/media/spicetify-marketplace.nix { };

    obsidian-plugins = final.callPackage ../pkgs/apps/notes/obsidian-plugins.nix { };

    grub-theme = final.callPackage ../pkgs/desktop/pwnbox-grub-theme.nix { };
  };
}
