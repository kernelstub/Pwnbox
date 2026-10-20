{
  lib,
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

  userJsPrefs =
    let
      parse =
        line:
        let
          m = builtins.match ''^[[:space:]]*user_pref\("([^"]+)",[[:space:]]*([^;]+)\);[[:space:]]*$'' line;
        in
        if m == null then
          null
        else
          {
            name = builtins.elemAt m 0;
            value = builtins.fromJSON (builtins.elemAt m 1);
          };
    in
    builtins.filter (p: p != null) (
      map parse (lib.splitString "\n" (builtins.readFile ../../../dotfiles/zen/user.js))
    );

  prefsFromUserJs = builtins.listToAttrs (map (p: lib.nameValuePair p.name p.value) userJsPrefs);
in
let
  wrapped = wrapFirefox browserForWrapper {
    pname = "zen-browser";
    version = zen-browser-unwrapped.version;

    extraPolicies = {
      DisableAppUpdate = true;
      Preferences = prefsFromUserJs // {
        "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
        "xpinstall.signatures.required" = false;
      };
      ExtensionSettings = {
        "styles@pwnbox.one" = {
          installation_mode = "removed";
        };
        "{73a6fe31-595d-460b-a920-fcc0f8843232}" = {
          installation_mode = "removed";
        };
        "pywalfox@frewacom.org" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/pywalfox/latest.xpi";
        };
        "uBlock0@raymondhill.net" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/ublock-origin/latest.xpi";
        };
        "{74145f27-f039-47ce-a470-a662b129930a}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/clearurls/latest.xpi";
        };
        "{036a55b4-5e72-4d05-a06c-cba2dfcc134a}" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/traduzir-paginas-web/latest.xpi";
        };
        "wappalyzer@crunchlabz.com" = {
          installation_mode = "force_installed";
          install_url = "https://addons.mozilla.org/firefox/downloads/latest/wappalyzer/latest.xpi";
        };
        "{d19a89b9-76c1-4a61-bcd4-49e8de916403}" = {
          installation_mode = "force_installed";
          install_url = "https://github.com/mullvad/browser-extension/releases/download/v0.9.10-firefox-beta/mullvad-browser-extension-0.9.10.xpi";
        };
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
