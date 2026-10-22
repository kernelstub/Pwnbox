{
  config,
  lib,
  pkgs,
  ...
}:
let
  dotfiles = ../../dotfiles;
  homeDir = config.home.homeDirectory;

  wallpapers = "${homeDir}/.local/share/pwnbox/wallpapers";
  gtkColors = "file://${homeDir}/.cache/pwnbox/theme/gtk-colors.css";

  gtk3ExtraCss = ''
    @import url("file://${homeDir}/.config/pwnbox/gtk/gtk-3.0-base.css");
    @import url("${gtkColors}");
  '';
  gtk4ExtraCss = ''
    @import url("file://${homeDir}/.config/pwnbox/gtk/gtk-4.0-base.css");
    @import url("${gtkColors}");
  '';
in
{
  home.sessionVariables = {
    XCURSOR_THEME = "Colloid-dark-cursors";
    XCURSOR_SIZE = "24";
    TERMINAL = "kitty";
  };

  gtk = {
    enable = true;

    theme = {
      name = "Colloid-Dark-Grey";
      package = pkgs.pwnbox.colloid-dark-grey;
    };

    iconTheme = {
      name = "Colloid-Grey-Dark";
      package = pkgs.colloid-icon-theme.override { colorVariants = [ "grey" ]; };
    };

    cursorTheme = {
      name = "Colloid-dark-cursors";
      size = 24;
      package = pkgs.pwnbox.colloid-cursors;
    };

    font = {
      name = "IoskeleyMono Nerd Font";
      size = 9;
    };

    gtk3.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };
    gtk4.extraConfig = {
      gtk-application-prefer-dark-theme = 1;
    };

    gtk3.extraCss = gtk3ExtraCss;
    gtk4.extraCss = gtk4ExtraCss;
  };

  xdg.configFile = {
    "pwnbox/gtk/gtk-3.0-base.css".source = "${dotfiles}/gnome/gtk/gtk-3.0/gtk.css";
    "pwnbox/gtk/gtk-4.0-base.css".source = "${dotfiles}/gnome/gtk/gtk-4.0/gtk.css";
  };

  dconf.enable = true;
  dconf.settings = {
    "org/gnome/desktop/interface" = {
      gtk-theme = "Colloid-Dark-Grey";
      icon-theme = "Colloid-Grey-Dark";
      cursor-theme = "Colloid-dark-cursors";
      color-scheme = "prefer-dark";
      accent-color = "slate";
      clock-format = "24h";
      font-name = "IoskeleyMono Nerd Font 9";
      document-font-name = "IoskeleyMono Nerd Font 9";
      monospace-font-name = "IoskeleyMono Nerd Font 11";
      font-hinting = "slight";
      enable-animations = true;
      enable-hot-corners = false;
      gtk-enable-primary-paste = true;
      overlay-scrolling = true;
      show-battery-percentage = false;
    };

    "org/gnome/desktop/wm/preferences" = {
      theme = "Colloid-Dark-Grey";
      titlebar-font = "IoskeleyMono Nerd Font 11";
      button-layout = "appmenu:";
      focus-mode = "mouse";
      num-workspaces = 5;
      auto-raise = false;
    };

    "org/gnome/mutter" = {
      dynamic-workspaces = false;
      edge-tiling = false;
      workspaces-only-on-primary = false;
      overlay-key = "Super_L";
    };

    "org/gnome/shell" = {
      disable-user-extensions = false;
      enabled-extensions = [
        "user-theme@gnome-shell-extensions.gcampax.github.com"
        "lockscreen-extension@pratap.fastmail.fm"
        "hidetopbar@mathieu.bidon.ca"
        "notification-configurator@exposedcat"
        "dash-to-dock@micxgx.gmail.com"
        "blur-my-shell@aunetx"
        "tilingshell@ferrarodomenico.com"
        "rounded-window-corners@fxgn"
      ];
      favorite-apps = [
        "dev.zed.Zed.desktop"
        "kitty.desktop"
        "org.gnome.Nautilus.desktop"
        "zen.desktop"
        "spotify.desktop"
        "signal-desktop.desktop"
        "discord.desktop"
        "obsidian.desktop"
        "org.gnome.Settings.desktop"
      ];
    };

    "org/gnome/shell/app-switcher" = {
      current-workspace-only = true;
    };

    "org/gnome/shell/extensions/user-theme" = {
      name = "Colloid-Dark-Grey";
    };

    "org/gnome/desktop/background" = {
      color-shading-type = "solid";
      picture-options = "zoom";
      primary-color = "#000000";
      secondary-color = "#000000";
      picture-uri = "file://${wallpapers}/wallhaven-6l52r6.jpg";
      picture-uri-dark = "file://${wallpapers}/wallhaven-6l52r6.jpg";
    };

    "org/gnome/desktop/applications/terminal" = {
      exec = "kitty";
    };

    "org/gnome/desktop/privacy" = {
      remember-recent-files = false;
      remove-old-trash-files = true;
      remove-old-temp-files = true;
      report-technical-problems = false;
    };
    "org/gnome/system/location" = {
      enabled = false;
    };
  };

  home.file.".themes/Colloid-Dark-Grey".source =
    "${pkgs.pwnbox.colloid-dark-grey}/share/themes/Colloid-Dark-Grey";
}
