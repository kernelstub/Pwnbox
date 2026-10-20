{
  lib,
  stdenvNoCC,
  appimageTools,
  simplex-chat-desktop,
  fontconfig,
  python3,
}:

let
  system = stdenvNoCC.hostPlatform.system;

  src = simplex-chat-desktop.passthru.sources.${system};

  appDir = appimageTools.extract {
    pname = "simplex-chat-desktop";
    version = simplex-chat-desktop.version;
    inherit src;
  };

  fhs = appimageTools.wrapType2 {
    pname = "simplex-chat-desktop";
    version = simplex-chat-desktop.version;
    inherit src;
    extraPkgs = pkgs: [ pkgs.libnotify ];
    extraBwrapArgs = [
      "--setenv _JAVA_AWT_WM_NONREPARENTING 1"
    ];
    extraInstallCommands = ''
      install --mode=444 -D ${appDir}/chat.simplex.app.desktop --target-directory=$out/share/applications
      substituteInPlace $out/share/applications/chat.simplex.app.desktop \
        --replace-fail 'Exec=simplex' 'Exec=simplex-chat-desktop'
      cp -r ${appDir}/usr/share/icons $out/share
    '';
  };
in
stdenvNoCC.mkDerivation {
  pname = "simplex-chat-desktop";
  version = simplex-chat-desktop.version;

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    install -Dm755 ${./simplex-launcher.sh} "$out/bin/simplex-chat-desktop"
    substituteInPlace "$out/bin/simplex-chat-desktop" \
      --replace-fail '@appDir@' '${appDir}' \
      --replace-fail '@fhsBin@' '${fhs}/bin/simplex-chat-desktop' \
      --replace-fail '@python3@' '${lib.getExe python3}' \
      --replace-fail '@fcMatch@' '${fontconfig}/bin/fc-match'
    ln -s ${fhs}/share $out/share
    runHook postInstall
  '';

  passthru = {
    inherit appDir;
    sources = simplex-chat-desktop.passthru.sources or { };
  };

  meta = simplex-chat-desktop.meta // {
    description = "${
      simplex-chat-desktop.meta.description or "Desktop application for SimpleX Chat"
    } (pwnbox: pywal theme + application font sync)";
  };
}
