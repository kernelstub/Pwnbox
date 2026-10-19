{
  lib,
  pkgs,
  inputs ? { },
  ...
}:
let
  inherit (lib) mkOption mkEnableOption types;

  categories = import ../../pkgs/categories.nix {
    inherit pkgs inputs;
    system = pkgs.stdenv.hostPlatform.system;
  };
in
{
  options.pwnbox = {
    username = mkOption {
      type = types.str;
      default = "pwnbox";
      description = "Name of the primary user account.";
    };

    fullName = mkOption {
      type = types.str;
      default = "pwnbox";
      description = "Full name (GECOS) of the primary user.";
    };

    email = mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Optional git e-mail address for the primary user.";
    };

    hostName = mkOption {
      type = types.str;
      default = "nixos";
      description = "Network hostname.";
    };

    timeZone = mkOption {
      type = types.str;
      default = "Europe/Berlin";
      description = "System time zone.";
    };

    locale = mkOption {
      type = types.str;
      default = "en_US.UTF-8";
      description = "Default system locale.";
    };

    extraGroups = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "Extra groups to add to the primary user.";
    };

    desktop = {
      enable = mkEnableOption "the Hyprland + GNOME Wayland desktop, sessions and login manager";

      resolution = mkOption {
        type = types.str;
        default = "highrr";
        example = "2560x1440@144";
        description = ''
          Preferred mode applied to every monitor by Hyprland
          (`monitor = , <resolution>, auto, auto`).  Defaults to `highrr`
          (each monitor's highest refresh rate); set to `highres` for the
          highest resolution, `preferred` for the EDID-preferred mode, or an
          explicit `WIDTHxHEIGHT@RATE` to force one mode on every monitor.
        '';
      };

      mainMonitor = mkOption {
        type = types.str;
        default = "";
        example = "DP-1";
        description = ''
          Connector name of the primary monitor.  When set, that monitor is
          pinned to position `0x0` (so it stays the primary display) and the
          Quickshell bar is shown only on it.  Empty (the default) keeps
          Hyprland's automatic arrangement and shows the bar on whichever
          monitor ends up at `0x0`.
        '';
      };

      leftMonitor = mkOption {
        type = types.str;
        default = "";
        example = "HDMI-A-1";
        description = ''
          Connector name of the monitor placed physically to the left of the
          main monitor.  When set, it is pinned with Hyprland's `auto-left`
          position so it lands at a negative `x` offset instead of the
          default right-hand arrangement.  Empty (the default) keeps
          Hyprland's automatic placement (left of the primary would need
          manual dragging in Hyprland).
        '';
      };

      accessibility = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Enable the at-spi2-core accessibility bus.  Disabling it stops the
          `at-spi-dbus-bus` / `org.a11y.atspi.Registry` user services and sets
          `NO_AT_BRIDGE=1` / `GTK_A11Y=none` for every session; GNOME
          force-enables the bus for its own session.  Turn it off if you do
          not use assistive technologies.
        '';
      };
    };

    performance = {
      enable = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Performance mode.  Uses the `performance` CPU governor instead of
          `balanced`, disables CPU core parking by shutting off deep C-states
          (`intel_idle.max_cstate=0` on Intel, `processor.max_cstate=1`
          everywhere, `amd_pstate=active` on AMD) and prevents
          power-profiles-daemon / thermald from overriding or throttling the
          CPU.  On systems with an NVIDIA GPU, driver power management is
          enabled so the card can run at full clocks.  All vendor-specific
          bits are applied only where they apply, so the same module is safe
          on Intel, AMD and NVIDIA machines.
        '';
      };

      lockFrequency = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Pin every core to its maximum clock by setting the cpufreq minimum
          to the maximum frequency.  Maximum single-thread latency, at the
          cost of power draw and heat even when idle.
        '';
      };
    };

    vpn = {
      mullvad = mkOption {
        type = types.bool;
        default = true;
        description = ''
          Install and run the Mullvad VPN daemon + GUI.  When disabled, the
          always-resident `mullvad-daemon` (~27 MB) is not started and the
          package is not installed.
        '';
      };
    };

    virtualisation = {
      docker = mkEnableOption "Docker";
      dockerOnBoot = mkOption {
        type = types.bool;
        default = false;
        description = ''
          Start the Docker daemon (`dockerd`) on boot.  When disabled (the
          default), dockerd is not started at boot in order to keep idle
          RAM/CPU usage minimal.  The Docker socket is still enabled, so the
          daemon starts on demand the first time the `docker` command is used.
        '';
      };
      libvirtd = mkEnableOption "libvirt / KVM virtualisation";
      wireshark = mkEnableOption "Wireshark and the wireshark group";
    };

    packages = {
      gaming = mkEnableOption "gaming and entertainment applications";
      creative = mkEnableOption "creative, media and office applications";
      hacking = mkEnableOption "pentesting and security tooling (the full pwnbox toolset)";

      toolset = lib.genAttrs (builtins.attrNames categories) (name: {
        enable = mkOption {
          type = types.bool;
          default = true;
          description = "Install the '${name}' pentest tool category.";
        };
      });
    };
  };
}
