{
  fetchurl,
  lib,
  runCommand,
}:
let
  plugins = {
    dataview = {
      repo = "blacksmithgu/obsidian-dataview";
      version = "0.5.70";
      main = "sha256-a7HPcBCvrYMOc1dfyg4r+9MnnFYuPZ0k8tL0UWHrfQA=";
      manifest = "sha256-kjXbRxEtqBuFWRx57LmuJXTl5yIHBW6XZHL5BhYoYYU=";
      styles = "sha256-MwbdkDLgD5ibpyM6N/0lW8TT9DQM7mYXYulS8/aqHek=";
    };
    templater-obsidian = {
      repo = "SilentVoid13/Templater";
      version = "2.26.0";
      main = "sha256-Cs1Fz9s6czfivvURaZvB+BncZGRa00gN8zV51C0ty6o=";
      manifest = "sha256-kcn6hRAIL/+gs9AiqsSYbjs5IpWxEm6Efq1+1yiRabg=";
      styles = "sha256-Z6bdLR1t7coSh8M0yohOxBlkM/ccpHOIoL0+rBTPi18=";
    };
    obsidian-git = {
      repo = "Vinzent03/obsidian-git";
      version = "2.41.1";
      main = "sha256-KKGK/KsdLxUqDTyJr/OOKpetC+GuqvmWMGEyM7vsbBs=";
      manifest = "sha256-XU0PQRUYY2wdKkgxQlqONIe5JbW9QTvgyiLm3jilk/c=";
      styles = "sha256-v6j71F/kn/NA/bGWuEut1jGu3l1vlnQPM26nec1EEAU=";
    };
    obsidian-kanban = {
      repo = "community-archive/obsidian-kanban";
      version = "2.0.51";
      main = "sha256-p+O9TPJfm39TqEHETOmQ2w7195VOvKsXrm3KgDEMOaw=";
      manifest = "sha256-JJdnhwl+rUZ5aeAUo1ZU56gOTbSal3aJpIr636FeGFQ=";
      styles = "sha256-7PbdMfFyfEQczm9UeUsNORbc//yH+he4VceboEqF2ac=";
    };
    obsidian-outliner = {
      repo = "vslinko/obsidian-outliner";
      version = "4.10.2";
      main = "sha256-PVvGNNMEXq1N+XR9B6tR8W2XIvRgH5/uJ+DH/pgo+zM=";
      manifest = "sha256-J3qIh+uVnMekrgR2CEIRU7NZvfRRwtZsqrkcNcqYuT8=";
      styles = "sha256-eSKiZIg4lOafIsN/VJdE99RtHekm/IAqpOlMdc0vvOs=";
    };
    obsidian-style-settings = {
      repo = "community-archive/obsidian-style-settings";
      version = "1.0.9";
      main = "sha256-GCirqs2rTFV4twWmJcWFswUS+O+tTHz8WhjnDMNVdGg=";
      manifest = "sha256-nP/cIM8qoTVIIOAFC2lLD5tXZEbj1dRKNq6LAYflv7g=";
      styles = "sha256-7nk30r5QZTqJzLMK5fBXKyNQfVt/EyjQBScaNjB1v9g=";
    };
    obsidian-latex-suite = {
      repo = "artisticat1/obsidian-latex-suite";
      version = "1.14.0";
      main = "sha256-isXiNKTiLSY6+YBgFZ/MFRry7Ki7lwbKxcbdEx9sRP4=";
      manifest = "sha256-dtAPEzxu94bTUjFedC06M6rJ7WoXTTKd94CapSvRxCw=";
      styles = "sha256-ouLvTepHnpwjd/CpiD/lOfwrEpskSGNCQwn4+SwdyBQ=";
    };
    quickadd = {
      repo = "chhoumann/quickadd";
      version = "2.32.1";
      main = "sha256-ZCOy0UtgvFH8a29h+DXgjFhC0o5aGkOrVgHM03tORMU=";
      manifest = "sha256-t2ELTB03wsc/eBwpTBo4DnMeeX+YWNLYJef6zBrDrdE=";
      styles = "sha256-lGfvNiLNETfOWgFI4W3iO59b6HvIwgT7YFDEj48pmU0=";
    };
  };

  asset =
    repo: version: file: hash:
    fetchurl {
      url = "https://github.com/${repo}/releases/download/${version}/${file}";
      sha256 = hash;
    };

  mkPlugin =
    id: spec:
    let
      mainJs = asset spec.repo spec.version "main.js" spec.main;
      manifest = asset spec.repo spec.version "manifest.json" spec.manifest;
      styles = asset spec.repo spec.version "styles.css" spec.styles;
    in
    ''
      mkdir -p "$out/${id}"
      cp ${mainJs} "$out/${id}/main.js"
      cp ${manifest} "$out/${id}/manifest.json"
      cp ${styles} "$out/${id}/styles.css"
    '';
in
runCommand "pwnbox-obsidian-plugins" { } (lib.concatStrings (lib.mapAttrsToList mkPlugin plugins))
