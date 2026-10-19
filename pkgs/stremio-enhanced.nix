{
  appimageTools,
  lib,
  fetchurl,
  makeWrapper,
  stdenv,
  nix-update-script,
  writeText,
  extraFonts ? [ ],
}:

appimageTools.wrapType2 rec {
  pname = "stremio-enhanced";
  version = "1.2.0";
  serverVersion = "v4.21.1";

  src = fetchurl {
    url =
      "https://github.com/REVENGE977/stremio-enhanced/releases/download/v${version}/Stremio.Enhanced-${version}"
      + lib.optionalString stdenv.hostPlatform.isAarch64 "-arm64"
      + ".AppImage";
    hash =
      if stdenv.hostPlatform.isAarch64 then
        "sha256-ceRVr7qJfFjNWQrJtOV6XLs8IpTjgtQJ1CDCXdVd1oM="
      else
        "sha256-a+knxg/rd5Ied4RVK8Gg7xeFElovJab0gqxpjs11fAU=";
  };

  server = fetchurl {
    url = "https://dl.strem.io/server/${serverVersion}/desktop/server.js";
    hash = "sha256-QF60lNZwhAajDnFsPPtauuel6ceot5RG1kw/ghOFkw8=";
  };

  nativeBuildInputs = [ makeWrapper ];

  extraPkgs =
    pkgs:
    with pkgs;
    [
      fairfax-hd
      ubuntu-classic
      spleen
      terminus_font_ttf
      iosevka
      jetbrains-mono
      inconsolata
      noto-fonts
      dejavu_fonts
      liberation_ttf
      nerd-fonts.iosevka
      nerd-fonts.jetbrains-mono
      nerd-fonts.meslo-lg
      nerd-fonts.fira-code
      noto-fonts-color-emoji
    ]
    ++ extraFonts;

  extraInstallCommands =
    let
      contents = appimageTools.extract { inherit pname version src; };
      fontsConf = writeText "fonts.conf" ''
        <?xml version="1.0"?>
        <!DOCTYPE fontconfig SYSTEM "urn:fontconfig:fonts.dtd">
        <fontconfig>
          <include ignore_missing="yes">/etc/fonts/fonts.conf</include>
          <dir>/usr/share/fonts</dir>
        </fontconfig>
      '';
    in
    ''
      wrapProgram $out/bin/${pname} \
        --add-flags "\''${NIXOS_OZONE_WL:+\''${WAYLAND_DISPLAY:+--ozone-platform-hint=auto --enable-features=WaylandWindowDecorations}}" \
        --set FONTCONFIG_FILE ${fontsConf}

      install -m 444 -D ${contents}/${pname}.desktop -t $out/share/applications
      substituteInPlace $out/share/applications/${pname}.desktop \
        --replace-warn 'Exec=AppRun' 'Exec=${pname}'
      cp -r ${contents}/usr/share/icons $out/share

      install -m 444 -D ${server} $out/share/stremio-enhanced/streamingserver/server.js
      printf '%s' '${serverVersion}' > $out/share/stremio-enhanced/streamingserver/version.txt
    '';

  passthru.updateScript = nix-update-script { };

  meta = with lib; {
    description = "Electron-based Stremio desktop client with plugins and themes support";
    homepage = "https://github.com/REVENGE977/stremio-enhanced";
    downloadPage = "https://github.com/REVENGE977/stremio-enhanced/releases";
    license = licenses.mit;
    sourceProvenance = with sourceTypes; [ binaryNativeCode ];
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
    ];
    mainProgram = "stremio-enhanced";
  };
}
