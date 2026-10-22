{
  lib,
  fetchFromGitHub,
  rustPlatform,
  pkg-config,
  libGL,
  libxkbcommon,
  wayland,
  wayland-protocols,
}:

rustPlatform.buildRustPackage rec {
  pname = "hyprcorrect";
  version = "0.6.0";

  src = fetchFromGitHub {
    owner = "jondkinney";
    repo = "hyprcorrect";
    tag = "v${version}";
    hash = "sha256-UmWkK0H1nUQMBgRhaTO+tPQqfVkT2Rbkj6r0rQnQnyU=";
  };

  cargoLock.lockFile = "${src}/Cargo.lock";

  # The only failing test shells out to the FHS path /usr/bin/python3,
  # which does not exist on NixOS. The runtime does not need it.
  doCheck = false;

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    libGL
    libxkbcommon
    wayland
    wayland-protocols
  ];

  postInstall = ''
    install -Dm644 packaging/hyprcorrect.desktop \
      $out/share/applications/hyprcorrect.desktop

    install -Dm644 assets/icons/hicolor/scalable/apps/hyprcorrect.svg \
      $out/share/icons/hicolor/scalable/apps/hyprcorrect.svg
    for size in 16 22 24 32 48 64 128 256 512; do
      install -Dm644 "assets/icons/hicolor/''${size}x''${size}/apps/hyprcorrect.png" \
        "$out/share/icons/hicolor/''${size}x''${size}/apps/hyprcorrect.png"
    done
  '';

  meta = with lib; {
    description = "Keyboard-driven desktop spelling and typo corrector";
    homepage = "https://github.com/jondkinney/hyprcorrect";
    changelog = "https://github.com/jondkinney/hyprcorrect/blob/v${version}/CHANGELOG.md";
    license = with licenses; [
      mit
      asl20
    ];
    maintainers = [ ];
    platforms = platforms.linux;
    mainProgram = "hyprcorrect";
  };
}
