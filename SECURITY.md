# Security policy

pwnbox is a hardened NixOS configuration. Security issues here are treated
differently from a regular application: there is no shipped binary, and most
runtime bugs originate in upstream projects (nixpkgs, Hyprland, Electron
apps, kernel), not in this repository.

## Supported versions

Only the latest commit of the `main` branch is supported. There are no
formal releases; the ISOs built by `scripts/iso.sh` are snapshots of the
flake at build time.

## In scope

Anything that weakens the box itself as configured:

- Hardening regressions (`modules/nixos/hardening.nix`, kernel command line,
  network and firewall settings, user/privilege defaults).
- Insecure defaults in the NixOS/home-manager modules, activation scripts or
  `scripts/install.sh`.
- Credential or key handling in the packaged apps, launchers and helper
  scripts (`dotfiles/scripts`, `scripts/`, `pkgs/`).
- Supply-chain issues introduced by this flake itself (inputs, overlays,
  `flake.lock` pins of untrustworthy sources).

## Out of scope

- Vulnerabilities in nixpkgs or the projects this flake builds on. Report
  those to the respective upstream project, or open a regular issue asking
  for an update pin.
- "It ships pentest tooling" is a feature, not a vulnerability. The toolset
  is expected to include offensive tools; the security goal is that the host
  itself stays hardened while running them.

## Reporting a vulnerability

Do **not** open a public issue for something that can compromise a user.

Use GitHub's private reporting instead:

1. Go to **Security → Report a vulnerability** (a GitHub Security Advisory).
2. Describe the issue, the affected files, and a minimal reproducer if you
   have one.
3. State the severity and whether you believe it is exploitable in practice.

You can also email [kern@skuntir.com](mailto:kern@skuntir.com) with the
subject `pwnbox security`. PGP is not required.

This is a one-person project: expect a best-effort response, no SLA and no
bug bounty. Fixes are committed to `main` as soon as they are ready; there
is no coordinated disclosure process or embargo beyond what the reporter
asks for.

## Acknowledgements

Credited in the commit and in the advisory when a report leads to a fix,
unless the reporter asks to stay anonymous.
