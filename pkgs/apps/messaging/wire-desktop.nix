{
  asar,
  lib,
  wire-desktop,
}:
wire-desktop.overrideAttrs (old: {
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ asar ];

  postInstall = (old.postInstall or "") + ''
    wire_asar_tmp="$(mktemp -d)"
    ${lib.getExe asar} extract "$out/share/wire-desktop/resources/app.asar" "$wire_asar_tmp"
    printf '\n' >> "$wire_asar_tmp/electron/dist/main.js"
    cat ${./wire-loader.js} >> "$wire_asar_tmp/electron/dist/main.js"
    ${lib.getExe asar} pack "$wire_asar_tmp" "$out/share/wire-desktop/resources/app.asar.new"
    chmod --reference="$out/share/wire-desktop/resources/app.asar" "$out/share/wire-desktop/resources/app.asar.new"
    mv -f "$out/share/wire-desktop/resources/app.asar.new" "$out/share/wire-desktop/resources/app.asar"
    rm -rf "$wire_asar_tmp"
  '';

  meta = (old.meta or { }) // {
    description = "${
      old.meta.description or "Modern, secure messenger for everyone"
    } (pwnbox: pywal theme + font injection)";
  };
})
