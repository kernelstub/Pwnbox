{
  config,
  lib,
  pkgs,
  ...
}:
let
  dockerKernelModules = [
    "overlay"
    "xt_addrtype"
    "nft_compat"
    "nft_chain_nat"
    "nft_nat"
    "nft_masq"
    "xt_MASQUERADE"
  ];
in
{
  virtualisation.docker.enable = config.pwnbox.virtualisation.docker;

  virtualisation.docker.enableOnBoot = config.pwnbox.virtualisation.dockerOnBoot;

  virtualisation.docker.daemon.settings.userland-proxy = false;

  boot.kernelModules = lib.optionals config.pwnbox.virtualisation.docker dockerKernelModules;

  virtualisation.libvirtd.enable = config.pwnbox.virtualisation.libvirtd;

  systemd.services.virt-secret-init-encryption = lib.mkIf config.pwnbox.virtualisation.libvirtd {
    unitConfig.ConditionPathExists = [
      ""
    ];
    serviceConfig.ExecStart = pkgs.writeShellScript "virt-secret-init-encryption" ''
      set -eu
      umask 0077
      key=/var/lib/libvirt/secrets/secrets-encryption-key
      if [ -s "$key" ] && "${pkgs.systemd}/bin/systemd-creds" decrypt \
          --name=secrets-encryption-key "$key" - >/dev/null 2>&1; then
        exit 0
      fi
      rm -f "$key"
      "${pkgs.coreutils}/bin/dd" if=/dev/random status=none bs=32 count=1 \
        | "${pkgs.systemd}/bin/systemd-creds" encrypt --name=secrets-encryption-key - "$key"
    '';
  };

  programs.wireshark.enable = config.pwnbox.virtualisation.wireshark;

  programs.virt-manager.enable = config.pwnbox.virtualisation.libvirtd;

  virtualisation.libvirtd.qemu.swtpm.enable = config.pwnbox.virtualisation.libvirtd;
}
