{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.pwnbox.performance;
  hasNvidia = lib.elem "nvidia" config.services.xserver.videoDrivers;
  x86 = lib.elem config.nixpkgs.hostPlatform.system [
    "x86_64-linux"
    "i686-linux"
  ];
in
{
  imports = [ ];

  config = lib.mkIf cfg.enable {
    powerManagement.cpuFreqGovernor = lib.mkDefault "performance";

    systemd.services.cpufreq-lock = lib.mkIf cfg.lockFrequency {
      wantedBy = [ "multi-user.target" ];
      after = [ "systemd-udev-settle.service" ];
      unitConfig.ConditionPathExists = "/sys/devices/system/cpu/cpu0/cpufreq";
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        for cpu in /sys/devices/system/cpu/cpu*/cpufreq; do
          max=$("${pkgs.coreutils}/bin/cat" "$cpu/scaling_max_freq")
          printf '%s' "$max" > "$cpu/scaling_min_freq" 2>/dev/null || true
        done
      '';
    };

    services.power-profiles-daemon.enable = false;

    services.thermald.enable = false;

    boot.kernelParams = [
      "processor.max_cstate=1"
    ]
    ++ lib.optionals x86 [
      "intel_idle.max_cstate=0"
      "amd_pstate=active"
    ];

    hardware.nvidia = lib.mkIf hasNvidia {
      powerManagement.enable = true;
    };

    boot.kernel.sysctl = {
      "kernel.numa_balancing" = 0;
      "kernel.sched_migration_cost_ns" = 5000000;
      "vm.stat_interval" = 10;
    };
  };
}
