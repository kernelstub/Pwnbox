{
  asar,
  lib,
  signal-desktop,
}:
signal-desktop.overrideAttrs (old: {
  nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ asar ];

  postInstall = (old.postInstall or "") + ''
    signal_asar_tmp="$(mktemp -d)"
    ${lib.getExe asar} extract "$out/share/signal-desktop/app.asar" "$signal_asar_tmp"
    printf '\n' >> "$signal_asar_tmp/bundles/main.js"
    cat ${./signal-loader.js} >> "$signal_asar_tmp/bundles/main.js"
    ${lib.getExe asar} pack "$signal_asar_tmp" "$out/share/signal-desktop/app.asar.new"
    chmod --reference="$out/share/signal-desktop/app.asar" "$out/share/signal-desktop/app.asar.new"
    mv -f "$out/share/signal-desktop/app.asar.new" "$out/share/signal-desktop/app.asar"
    rm -rf "$signal_asar_tmp"
  '';

  meta = (old.meta or { }) // {
    description = "${
      old.meta.description or "Signal private messenger"
    } (pwnbox: pywal theme + font injection)";
  };
})
