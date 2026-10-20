{
  lib,
  stdenvNoCC,
  grub2,
  imagemagick,
}:
stdenvNoCC.mkDerivation {
  pname = "pwnbox-grub-theme";
  version = "1.0.0";

  src = ../../dotfiles;
  themeSrc = ./grub-theme;

  nativeBuildInputs = [
    grub2
    imagemagick
  ];

  dontConfigure = true;

  buildPhase = ''
    runHook preBuild

    magick config/hypr/wall.png \
      -resize '1920x1080^' -gravity center -extent 1920x1080 \
      -blur 0x16 -fill '#080808' -colorize 55% \
      -define png:color-type=2 -strip \
      background.png

    magick config/fastfetch/pwnbox.png -resize 192x192 \
      -define png:color-type=6 -strip \
      logo.png

    grub-mkfont -s 14 -o manrope-14.pf2 gnome/fonts/Manrope-Regular.ttf
    grub-mkfont -s 16 -o manrope-16.pf2 gnome/fonts/Manrope-Regular.ttf

    magick -size 16x16 canvas:none \
      -fill 'rgba(204,204,204,0.10)' -draw 'roundrectangle 0,0,15,15,7,7' \
      -define png:color-type=6 -strip \
      select_box.png

    magick -size 16x16 canvas:none \
      -fill 'rgba(8,8,8,0.88)' -draw 'roundrectangle 0,0,15,15,7,7' \
      -define png:color-type=6 -strip \
      terminal_box.png

    for piece in nw n ne e se s sw w c; do
      cp select_box.png "select_$piece.png"
      cp terminal_box.png "terminal_box_$piece.png"
    done
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp "$themeSrc/theme.txt" "$out/theme.txt"
    cp background.png logo.png "$out/"
    cp manrope-14.pf2 manrope-16.pf2 "$out/"
    for piece in nw n ne e se s sw w c; do
      cp "select_$piece.png" "terminal_box_$piece.png" "$out/"
    done
    runHook postInstall
  '';

  meta = {
    description = "pwnbox GRUB boot theme (matches the hyprlock lock screen)";
    license = lib.licenses.unlicense;
    platforms = lib.platforms.all;
  };
}
