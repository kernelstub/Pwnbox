{ pkgs, ... }:
with pkgs;
[
  awscli2
  aws-vault
  aws-nuke
  google-cloud-sdk
  azure-cli

  terraform
  terragrunt
  checkov

  pacu
  prowler

  s3cmd
  rclone
  doctl
  cloud-nuke

  minio-client
  cloudflared
  glab
  eksctl
  vault
  packer
  opentofu
  terraform-docs
  tfsec
  aws-sam-cli
  s5cmd
  azure-storage-azcopy
]
