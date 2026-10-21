{
  runCommand,
  wrapFirefox,
  zen-browser-unwrapped,
  zip,
  pywalfox,
}:
let
  browserForWrapper = zen-browser-unwrapped // {
    version = zen-browser-unwrapped.firefoxVersion;
  };

  pwnboxStyles = runCommand "pwnbox-styles.xpi" { nativeBuildInputs = [ zip ]; } ''
    mkdir src
    cp ${../../../dotfiles/zen/extension}/* src/
    (cd src && zip -q -r "$out" .)
  '';

  wrapped = wrapFirefox browserForWrapper {
    pname = "zen-browser";
    version = zen-browser-unwrapped.version;

    extraPolicies = {
      # Zen itself cannot update inside the Nix store; `upd` ships new builds.
      DisableAppUpdate = true;
      ExtensionSettings = {
        "styles@pwnbox.one" = {
          installation_mode = "removed";
        };
        "{73a6fe31-595d-460b-a920-fcc0f8843232}" = {
          installation_mode = "removed";
        };
        # Only the theming integration is managed; everything else is left to
        # the user so Zen behaves like a normal browser.
        "pywalfox@frewacom.org" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/pywalfox/latest.xpi";
        };
      };
      Preferences = {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
      };
    };

    nativeMessagingHosts = [ pywalfox ];
  };
in
wrapped.overrideAttrs (old: {
  buildCommand = (old.buildCommand or "") + ''
    mkdir -p "$out/lib/${browserForWrapper.libName}/distribution/extensions"
    cp ${pwnboxStyles} "$out/lib/${browserForWrapper.libName}/distribution/extensions/kern@skuntir.com.xpi"
  '';
})
