{ pkgs, ... }:
with pkgs;
[
  docker
  podman
  distrobox
  docker-compose
  nerdctl

  trivy
  grype
  syft
  dive

  buildah
  skopeo
  crun
  runc
  ctop
  lazydocker
  podman-tui
  regctl
  oras
]
