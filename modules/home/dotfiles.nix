{
  config,
  lib,
  pkgs,
  pwnboxDisplay ? "1920x1080",
  pwnboxMainMonitor ? "",
  pwnboxLeftMonitor ? "",
  pwnboxTimezone ? "",
  ...
}:
let
  dotfiles = ../../dotfiles;
  homeDir = config.home.homeDirectory;
  configDir = name: { source = "${dotfiles}/config/${name}"; };

  tpl = path: {
    text = builtins.replaceStrings [ "@HOME@" ] [ homeDir ] (builtins.readFile "${dotfiles}/${path}");
  };

  vdesktopsLine = "";

  mainMonitorLine =
    if pwnboxMainMonitor != "" then "monitor = ${pwnboxMainMonitor},${pwnboxDisplay},0x0,1\n" else "";

  leftMonitorLine =
    if pwnboxLeftMonitor != "" then
      "monitor = ${pwnboxLeftMonitor},${pwnboxDisplay},auto-left,1\n"
    else
      "";

  hyprlandConf =
    builtins.replaceStrings
      [ "@RESOLUTION@" "@HOME@" "@MAINMONITOR@" "@SECONDARYMONITOR@" "@TIMEZONE@" "@VDESKTOPS@" ]
      [
        pwnboxDisplay
        homeDir
        mainMonitorLine
        leftMonitorLine
        (if pwnboxTimezone != "" then
          "env = TZ,${pwnboxTimezone}\nenv = TZDIR,/etc/zoneinfo"
        else
          "")
        vdesktopsLine
      ]
      (builtins.readFile "${dotfiles}/config/hypr/hyprland.conf");

  shellQml = builtins.replaceStrings [ "@MAINMONITOR@" ] [ pwnboxMainMonitor ] (
    builtins.readFile "${dotfiles}/config/quickshell/shell.qml"
  );

  themes = ../../dotfiles/themes;
  customThemes = builtins.listToAttrs (
    map
      (name: {
        name = "pwnbox/themes/${name}";
        value.source = "${themes}/${name}";
      })
      (
        builtins.attrNames (
          lib.filterAttrs (
            name: type: type == "directory" && builtins.pathExists "${themes}/${name}/theme.conf"
          ) (builtins.readDir themes)
        )
      )
  );
in
{
  xdg.enable = true;

  xdg.configFile = {
    "bat" = configDir "bat";
    "cava" = configDir "cava";
    "fuzzel/fuzzel.ini" = tpl "config/fuzzel/fuzzel.ini";
    "kitty/kitty.conf" = tpl "config/kitty/kitty.conf";
    "fastfetch" = configDir "fastfetch";
    "rofi/config.rasi" = tpl "config/rofi/config.rasi";
    "rofi/menu.rasi" = tpl "config/rofi/menu.rasi";
    "rofi/picker.rasi" = tpl "config/rofi/picker.rasi";
    "rofi/barstyle.rasi" = tpl "config/rofi/barstyle.rasi";
    "rofi/custom.rasi" = tpl "config/rofi/custom.rasi";
    "wal/templates".source = "${dotfiles}/config/wal/templates";
    "wal/monochrome".source = "${dotfiles}/config/wal/monochrome";

    "micro/settings.json".source = "${dotfiles}/config/micro/settings.json";
    "micro/bindings.json".source = "${dotfiles}/config/micro/bindings.json";
    "micro/colorschemes".source = "${dotfiles}/config/micro/colorschemes";

    "zathura/zathurarc" = tpl "config/zathura/zathurarc";

    "telegram/awesome.tdesktop-theme".source = "${dotfiles}/config/telegram/awesome.tdesktop-theme";

    "equibop/theme-base.css".source = "${dotfiles}/config/equibop/theme-base.css";

    "spicetify/Themes/pwnbox/user-base.css".source =
      "${dotfiles}/config/spicetify/Themes/pwnbox/user-base.css";
    "spicetify/CustomApps/marketplace".source =
      "${pkgs.pwnbox.spicetify-marketplace}/share/spicetify-marketplace/marketplace";

    "nvim/lua".source = "${dotfiles}/config/nvim/lua";

    "hypr/hypridle.conf".source = "${dotfiles}/config/hypr/hypridle.conf";
    "hypr/wall.png".source = "${dotfiles}/config/hypr/wall.png";
    "hypr/hyprland.conf".text = hyprlandConf;

    "ranger/rc.conf".source = "${dotfiles}/config/ranger/rc.conf";
    "ranger/commands.py".source = "${dotfiles}/config/ranger/commands.py";
    "ranger/rifle.conf".source = "${dotfiles}/config/ranger/rifle.conf";
    "ranger/scope.sh".source = "${dotfiles}/config/ranger/scope.sh";
    "ranger/plugins".source = "${dotfiles}/config/ranger/plugins";

    "fontconfig/fonts.conf".text = ''
      <?xml version="1.0"?>
      <!DOCTYPE fontconfig SYSTEM "fonts.dtd">
      <fontconfig>
        <match target="scan">
          <test name="family"><string>Fairfax HD</string></test>
          <edit name="spacing" mode="assign"><const>mono</const></edit>
        </match>
        <match target="scan">
          <test name="family"><string>Fairfax Hax HD</string></test>
          <edit name="spacing" mode="assign"><const>mono</const></edit>
        </match>
        <match target="scan">
          <test name="family"><string>Fairfax Pona HD</string></test>
          <edit name="spacing" mode="assign"><const>mono</const></edit>
        </match>
      </fontconfig>
    '';

    "pywalfox/config.json".text = builtins.toJSON { profile_path = "${homeDir}/.config/zen"; };

    "pwnbox/zen/userstyles".source = "${dotfiles}/zen/userstyles";
    "pwnbox/ida".source = "${dotfiles}/ida";
  }
  // builtins.listToAttrs (
    map
      (name: {
        name = "quickshell/${name}";
        value.source = "${dotfiles}/config/quickshell/${name}";
      })
      (
        builtins.filter (n: n != "Theme.js") (
          builtins.attrNames (builtins.readDir "${dotfiles}/config/quickshell")
        )
      )
  )
  // customThemes
  // {
    "quickshell/shell.qml".text = shellQml;
  };

  xdg.dataFile."applications/spotify.desktop".text = ''
    [Desktop Entry]
    Type=Application
    Name=Spotify
    GenericName=Music Player
    Comment=Spotify (Spicetify, pwnbox theme)
    Exec=${homeDir}/.scripts/pwnbox-spotify launch %U
    TryExec=${homeDir}/.scripts/pwnbox-spotify
    Icon=spotify-client
    Terminal=false
    MimeType=x-scheme-handler/spotify;
    Categories=Audio;Music;Player;AudioVideo;
    StartupWMClass=spotify
  '';

  home.file = {
    ".local/share/pwnbox/wallpapers".source = "${dotfiles}/gnome/wallpapers";

    ".mozilla/native-messaging-hosts/pywalfox.json".text = builtins.toJSON {
      name = "pywalfox";
      description = "Native app used alongside the Pywalfox addon";
      path = "${lib.getExe pkgs.pywalfox-native}";
      type = "stdio";
      allowed_extensions = [ "pywalfox@frewacom.org" ];
    };

    ".local/bin/spotify" = {
      text = ''
        #!/usr/bin/env bash
        exec "$HOME/.scripts/pwnbox-spotify" launch "$@"
      '';
      executable = true;
    };
  }
  // builtins.listToAttrs (
    map (name: {
      name = ".scripts/${name}";
      value = {
        text = builtins.readFile (dotfiles + "/scripts/${name}");
        executable = true;
      };
    }) (builtins.attrNames (builtins.readDir (dotfiles + "/scripts")))
  );

  home.activation.pwnboxMigrateZathura = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    if [ -L "$HOME/.config/zathura" ]; then
      run rm -f "$HOME/.config/zathura"
    fi
  '';

  home.activation.pwnboxMigrateScripts = lib.hm.dag.entryBefore [ "writeBoundary" ] ''
    if [ -L "$HOME/.scripts" ]; then
      run rm -f "$HOME/.scripts"
    fi
  '';

  systemd.user.services.pwnbox-styles = {
    Unit = {
      Description = "pwnbox stylus userstyle server";
    };
    Install.WantedBy = [ "default.target" ];
    Service = {
      ExecStartPre = "${pkgs.coreutils}/bin/mkdir -p %h/.cache/pwnbox/theme/userstyles";
      ExecStart = "${pkgs.python3}/bin/python3 -m http.server 8311 --bind 127.0.0.1 -d %h/.cache/pwnbox/theme/userstyles";
      Restart = "on-failure";
    };
  };

  # CEF can leave renderer/GPU helpers behind after a crash even though the
  # top-level Spotify process is gone. Reap only those leftovers; a healthy
  # running client is left alone.
  systemd.user.services.pwnbox-spotify-clean = {
    Unit = {
      Description = "Reap leftover Spotify helper processes";
      ConditionPathExists = "${homeDir}/.scripts/pwnbox-spotify";
    };
    Service = {
      Type = "oneshot";
      ExecStart = "${homeDir}/.scripts/pwnbox-spotify cleanup";
    };
  };

  systemd.user.timers.pwnbox-spotify-clean = {
    Unit = {
      Description = "Periodically reap leftover Spotify processes";
    };
    Timer = {
      OnBootSec = "5min";
      OnUnitActiveSec = "10min";
      Unit = "pwnbox-spotify-clean.service";
    };
    Install.WantedBy = [ "timers.target" ];
  };

  home.activation.pwnboxIdaPlugin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if [ -d "$HOME/.idapro" ]; then
      run mkdir -p "$HOME/.idapro/plugins"
      run cp -a ${dotfiles}/ida/plugin/. "$HOME/.idapro/plugins/" 2>/dev/null || true
      run chmod -R u+w "$HOME/.idapro/plugins" 2>/dev/null || true
    fi

    ida_bin="$(command -v ida 2>/dev/null || true)"
    if [ -n "$ida_bin" ]; then
      for ida_entry in "$HOME/.local/share/applications"/com.hex_rays.IDA*.desktop; do
        [ -f "$ida_entry" ] || continue
        run chmod u+w "$ida_entry"
        run sed -i -E "s|^Exec=.*|Exec=\"$ida_bin\" %f|" "$ida_entry"
      done
    fi
  '';

  home.activation.pwnboxObsidian = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        vault="$HOME/Documents/Notes"
        run mkdir -p "$vault/.obsidian/plugins" "$vault/.obsidian/snippets"
        run cp -n ${dotfiles}/config/obsidian/no-scrollbars.css "$vault/.obsidian/snippets/no-scrollbars.css"

        if ! pgrep -f 'obsidian' >/dev/null 2>&1; then
          for id in dataview templater-obsidian obsidian-git obsidian-kanban obsidian-outliner obsidian-style-settings obsidian-latex-suite quickadd; do
            if [ ! -f "$vault/.obsidian/plugins/$id/main.js" ]; then
              run mkdir -p "$vault/.obsidian/plugins/$id"
              run cp -a ${pkgs.pwnbox.obsidian-plugins}/$id/. "$vault/.obsidian/plugins/$id/"
              run chmod -R u+w "$vault/.obsidian/plugins/$id"
            fi
          done

          if [ ! -f "$vault/.obsidian/community-plugins.json" ]; then
            run cat > "$vault/.obsidian/community-plugins.json" <<'JSON'
    ["dataview","templater-obsidian","obsidian-git","obsidian-kanban","obsidian-outliner","obsidian-style-settings","obsidian-latex-suite","quickadd"]
    JSON
          fi

          if [ ! -f "$vault/.obsidian/appearance.json" ]; then
            run cat > "$vault/.obsidian/appearance.json" <<'JSON'
    {
      "baseFontSize": 16,
      "theme": "obsidian",
      "translucency": false,
      "cssTheme": "",
      "textFontFamily": "IoskeleyMono Nerd Font",
      "interfaceFontFamily": "IoskeleyMono Nerd Font",
      "monospaceFontFamily": "IoskeleyMono Nerd Font",
      "enabledCssSnippets": [
        "pwnbox",
        "no-scrollbars"
      ],
      "accentColor": "",
      "windowFrameStyle": "native"
    }
    JSON
          fi
        fi
  '';

  home.activation.pwnboxStremioServer = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    server_src="${pkgs.pwnbox.stremio-enhanced}/share/stremio-enhanced/streamingserver"
    if [ -f "$server_src/server.js" ]; then
      run mkdir -p "$HOME/.config/stremio-enhanced/streamingserver"
      run cp -n "$server_src/server.js" "$HOME/.config/stremio-enhanced/streamingserver/server.js"
      run cp -n "$server_src/version.txt" "$HOME/.config/stremio-enhanced/streamingserver/version.txt"
    fi
  '';

  home.activation.pwnboxFonts = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if command -v fc-cache >/dev/null 2>&1; then
      run fc-cache -f >/dev/null 2>&1 || true
    fi
  '';

  home.activation.pwnboxZenChrome = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        zen_profiles="$HOME/.config/zen"
        if [ -f "$zen_profiles/profiles.ini" ]; then
          profile="$(sed -n 's/^Path=//p' "$zen_profiles/profiles.ini" | head -n1)"
          if [ -n "$profile" ]; then
            new_user_js="${dotfiles}/zen/user.js"
            # Previous pwnbox releases installed a privacy/security-hardening
            # user.js. Remove those prefs from prefs.js before replacing it,
            # otherwise the old values survive the file removal.
            if [ -f "$zen_profiles/$profile/user.js" ] && ! cmp -s "$new_user_js" "$zen_profiles/$profile/user.js"; then
              run ${pkgs.python3}/bin/python3 ${dotfiles}/scripts/pwnbox-zen-unharden \
                "$zen_profiles/$profile/user.js" "$zen_profiles/$profile/prefs.js"
            fi
            run install -m 0644 "$new_user_js" "$zen_profiles/$profile/user.js"
            chrome="$zen_profiles/$profile/chrome"
            run mkdir -p "$chrome"
            for pair in \
              "userChrome.css:${dotfiles}/config/wal/monochrome/userChrome.css" \
              "userContent.css:${dotfiles}/config/wal/monochrome/userContent.css"; do
              f="''${pair%%:*}"
              src="''${pair#*:}"
              if [ ! -e "$chrome/$f" ]; then
                run install -m 0644 "$src" "$chrome/$f"
              else
                run chmod u+w "$chrome/$f" 2>/dev/null || true
              fi
            done
            for stale_id in styles@pwnbox.one {73a6fe31-595d-460b-a920-fcc0f8843232}; do
              if [ -f "$zen_profiles/$profile/extensions/$stale_id.xpi" ]; then
                run rm -f "$zen_profiles/$profile/extensions/$stale_id.xpi"
              fi
            done
            ext_xpi="$zen_profiles/$profile/extensions/kern@skuntir.com.xpi"
            ext_size="$(wc -c < "$ext_xpi" 2>/dev/null || printf '0')"
            if [ ! -f "$ext_xpi" ] || [ "$ext_size" -lt 1000 ]; then
              run mkdir -p "$zen_profiles/$profile/extensions"
              run sed -i '/^user_pref("extensions.installedDistroAddon.kern@skuntir.com"/d' "$zen_profiles/$profile/prefs.js" 2>/dev/null || true
              run ${pkgs.python3}/bin/python3 - "$ext_xpi" <<'PYEOF' || true
    import os
    import sys
    import zipfile

    src = os.path.join("${dotfiles}", "zen", "extension")
    dst = sys.argv[1]
    with zipfile.ZipFile(dst, "w", zipfile.ZIP_DEFLATED, strict_timestamps=False) as z:
        for name in sorted(os.listdir(src)):
            z.write(os.path.join(src, name), name)
    PYEOF
            fi
          fi
        fi
  '';

  home.activation.pwnboxTheme = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    theme_dir="$HOME/.cache/pwnbox/theme"
    run mkdir -p "$theme_dir"
    run cp -n ${dotfiles}/config/wal/monochrome/* "$theme_dir"/ 2>/dev/null || true
    run mkdir -p "$HOME/.config/quickshell"
    if [ ! -e "$HOME/.config/quickshell/Theme.js" ]; then
      run cp -f ${dotfiles}/config/wal/monochrome/Theme.js "$HOME/.config/quickshell/Theme.js"
    fi
    run chmod u+w "$HOME/.config/quickshell/Theme.js" 2>/dev/null || true
    hyprlock_conf="$HOME/.config/hypr/hyprlock.conf"
    if [ -L "$hyprlock_conf" ]; then
      run rm -f "$hyprlock_conf"
    fi
    if [ -f "$hyprlock_conf.hm-backup" ]; then
      if [ ! -e "$hyprlock_conf" ]; then
        run mv -f "$hyprlock_conf.hm-backup" "$hyprlock_conf"
      else
        run rm -f "$hyprlock_conf.hm-backup"
      fi
    fi
    if [ ! -e "$hyprlock_conf" ]; then
      run cp -f ${dotfiles}/config/hypr/hyprlock.conf "$hyprlock_conf"
    fi
    run chmod u+w "$hyprlock_conf" 2>/dev/null || true
    if [ ! -e "$theme_dir/barstyle" ]; then
      run sh -c "printf '%s' islands > '$theme_dir/barstyle'"
    fi
    if [ ! -e "$theme_dir/radius-window" ]; then
      run sh -c "printf '%s' 9 > '$theme_dir/radius-window'"
    fi
    if [ ! -e "$theme_dir/radius-ui" ]; then
      run sh -c "printf '%s' 9 > '$theme_dir/radius-ui'"
    fi
    if [ ! -e "$theme_dir/blur" ]; then
      run sh -c "printf '%s' on > '$theme_dir/blur'"
    fi
    if [ ! -e "$theme_dir/opacity" ]; then
      if [ "$(cat "$theme_dir/blur" 2>/dev/null || echo on)" = "off" ]; then
        run sh -c "printf '%s' 100 > '$theme_dir/opacity'"
      else
        run sh -c "printf '%s' 92 > '$theme_dir/opacity'"
      fi
    fi
    if [ ! -e "$theme_dir/animations" ]; then
      run sh -c "printf '%s' on > '$theme_dir/animations'"
    fi
    if [ ! -e "$theme_dir/font-size-ui" ]; then
      run sh -c "printf '%s' 9 > '$theme_dir/font-size-ui'"
    fi
    if [ ! -e "$theme_dir/font-size-app" ]; then
      run sh -c "printf '%s' 9 > '$theme_dir/font-size-app'"
    fi
    if [ -L "$HOME/.config/spicetify/Themes/pwnbox/user.css" ]; then
      run rm -f "$HOME/.config/spicetify/Themes/pwnbox/user.css"
    fi
    run mkdir -p "$HOME/.config/zed/themes"
    zed_settings="$HOME/.config/zed/settings.json"
    if [ -L "$zed_settings" ]; then
      run rm -f "$zed_settings"
    fi
    if [ -f "$zed_settings.hm-backup" ]; then
      if [ ! -e "$zed_settings" ]; then
        run mv -f "$zed_settings.hm-backup" "$zed_settings"
      else
        run rm -f "$zed_settings.hm-backup"
      fi
    fi
    if [ ! -e "$zed_settings" ]; then
      run cp -f ${dotfiles}/config/zed/settings.json "$zed_settings"
    fi
    run chmod u+w "$zed_settings" 2>/dev/null || true
    if [ ! -e "$HOME/.config/zed/themes/pwnbox.json" ]; then
      run cp -f ${dotfiles}/config/wal/monochrome/pwnbox.json "$HOME/.config/zed/themes/pwnbox.json"
    fi
    run cp -f ${dotfiles}/config/zed/themes/kerne.json "$HOME/.config/zed/themes/kerne.json"
    run chmod u+w "$HOME/.config/zed/themes/pwnbox.json" "$HOME/.config/zed/themes/kerne.json" 2>/dev/null || true
    run sh -c 'chmod -R u+w "$HOME/.cache/pwnbox/theme" 2>/dev/null || true'
    if [ -x "$HOME/.scripts/pwnbox-theme" ]; then
      run sh -c 'PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$(id -un)/bin:$HOME/.nix-profile/bin:$PATH" "$HOME/.scripts/pwnbox-theme" borders >/dev/null 2>&1 || true'
      run sh -c 'PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$(id -un)/bin:$HOME/.nix-profile/bin:$PATH" "$HOME/.scripts/pwnbox-theme" userstyles >/dev/null 2>&1 || true'
      run sh -c 'PATH="/run/current-system/sw/bin:/etc/profiles/per-user/$(id -un)/bin:$HOME/.nix-profile/bin:$PATH" "$HOME/.scripts/pwnbox-theme" refresh >/dev/null 2>&1 || true'
    fi
    if command -v systemctl >/dev/null 2>&1; then
      run systemctl --user start pwnbox-styles.service 2>/dev/null || true
    fi
    if command -v qs >/dev/null 2>&1 && [ -x "$HOME/.scripts/pwnbox-theme" ]; then
      run sh -c '"$HOME/.scripts/pwnbox-theme" restart-shell >/dev/null 2>&1 || true'
    fi
  '';
}
