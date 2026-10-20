{
  asar,
  jq,
  lib,
  stdenvNoCC,
  element-desktop,
  element-web-unwrapped,
}:
let
  element-web-labs = stdenvNoCC.mkDerivation {
    pname = "element-web-pwnbox";
    inherit (element-web-unwrapped) version;
    dontUnpack = true;
    nativeBuildInputs = [ jq ];
    installPhase = ''
      runHook preInstall
      mkdir -p "$out"
      cp -r ${element-web-unwrapped}/. "$out"/
      jq '.show_labs_settings = true' "$out/config.json" > "$out/config.json.new"
      mv "$out/config.json.new" "$out/config.json"
      runHook postInstall
    '';
  };
in
(element-desktop.override {
  element-web = element-web-labs;
}).overrideAttrs
  (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ asar ];

    postInstall = (old.postInstall or "") + ''
      element_asar_tmp="$(mktemp -d)"
      ${lib.getExe asar} extract "$out/share/element/app.asar" "$element_asar_tmp"
      printf '\n' >> "$element_asar_tmp/lib/electron-main.js"
      cat ${./element-loader.js} >> "$element_asar_tmp/lib/electron-main.js"
      ${lib.getExe asar} pack "$element_asar_tmp" "$out/share/element/app.asar.new"
      chmod --reference="$out/share/element/app.asar" "$out/share/element/app.asar.new"
      mv -f "$out/share/element/app.asar.new" "$out/share/element/app.asar"
      rm -rf "$element_asar_tmp"
    '';

    meta = (old.meta or { }) // {
      description = "${
        old.meta.description or "Feature-rich client for Matrix.org"
      } (pwnbox: pywal theme + font injection)";
    };
  })
