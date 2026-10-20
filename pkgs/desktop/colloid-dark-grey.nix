{
  lib,
  runCommand,
  colloid-gtk-theme,
  accent ? "#454545",
}:
runCommand "colloid-dark-grey"
  {
    passthru = {
      inherit accent;
    };

    meta = {
      description = "Colloid-Dark GTK/Shell theme with a monochrome gray accent";
      homepage = "https://github.com/vinceliuice/Colloid-gtk-theme";
      license = lib.licenses.gpl3Only;
      platforms = lib.platforms.unix;
    };
  }
  ''
    theme=Colloid-Dark-Grey
    src=${colloid-gtk-theme}/share/themes/Colloid-Dark
    dest="$out/share/themes/$theme"

    mkdir -p "$dest"
    cp -rL "$src"/. "$dest"/
    chmod -R u+w "$dest"

    sed -i \
      -e 's/^Name=Colloid-Dark$/Name=Colloid-Dark-Grey/' \
      -e 's/^GtkTheme=Colloid-Dark$/GtkTheme=Colloid-Dark-Grey/' \
      -e 's/^MetacityTheme=Colloid-Dark$/MetacityTheme=Colloid-Dark-Grey/' \
      "$dest/index.theme"

    find "$dest" -type f \
      \( -name '*.css' -o -name '*.svg' -o -name '*.rc' -o -name 'gtkrc' \) -print0 |
      xargs -0 sed -i \
        -e 's/#5b9bf8/${accent}/gI' \
        -e 's/#438cf7/#383838/gI' \
        -e 's/#65a1f8/#555555/gI' \
        -e 's/#73aaf9/#525252/gI' \
        -e 's/#74aaf9/#5a5a5a/gI' \
        -e 's/#87b6fa/#606060/gI' \
        -e 's/#bdd7fc/#6e6e6e/gI' \
        -e 's/#5bd3f8/#4d4d4d/gI' \
        -e 's/#8ce0fa/#5f5f5f/gI' \
        -e 's/#3483f6/#4a4a4a/gI' \
        -e 's/#2a7df6/#474747/gI' \
        -e 's/#126ef5/#3f3f3f/gI' \
        -e 's/#2ac6f6/#4d4d4d/gI' \
        -e 's/rgba(91, *155, *248/rgba(69, 69, 69/gI' \
        -e 's/rgba(91, *211, *248/rgba(69, 69, 69/gI' \
        -e 's/-st-accent-fg-color/#ffffff/gI' \
        -e 's/-st-accent-color/${accent}/gI'
  ''
