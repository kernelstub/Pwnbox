# Contributing

Thanks for wanting to contribute. pwnbox is a personal project that happens
to be public; contributions that keep it useful for everyone are welcome.

## How to contribute

1. Look through the [open issues](https://github.com/kernelstub/Pwnbox/issues)
   or start a discussion about what you want to change.
2. Fork the repository and work on a branch.
3. Open a pull request against `main` and fill in the PR template.

Small, focused changes are easier to review than large rewrites. If you plan
something big (a new module, a package overhaul), open an issue first.

## Where things live

The repository layout and how the pieces fit together are documented in
[docs/architecture.md](docs/architecture.md). In short:

- `modules/` — NixOS and home-manager modules (`pwnbox.*` option tree).
- `pkgs/` — custom packages and the pentest toolset categories.
- `overlays/` — the nixpkgs overlay.
- `dotfiles/` — configs, scripts (`pwnbox-theme`, …) and the Zen site
  themes.
- `hosts/` — per-machine configurations; `iso/` and `installer/` are image
  profiles.
- `docs/` — the manual. Update it when you change behaviour.

## Style

- Nix: the flake is formatted with `nixfmt`. Run it on every file you touch.
- Shell: `bash -n dotfiles/scripts/pwnbox-theme` must pass.
- Docs and commit messages: plain text, **no emojis**.
- Commit messages: short lowercase-prefix summary, optional body
  (`fix: …`, `feat: …`, `docs: …`), matching the existing history.
- Keep generated files out of the flake; only their bases live there
  (see the style guidelines in [docs/development.md](docs/development.md)).

## Testing

Before opening a PR:

```bash
nixfmt --check <changed .nix files>
bash -n dotfiles/scripts/pwnbox-theme
./install.sh build   # or: nix build .#nixosConfigurations.<host>.config.system.build.toplevel
```

The full checklist is in [docs/development.md](docs/development.md#testing).

## License

This repository is released into the public domain under the
[Unlicense](LICENSE). By contributing you agree to release your
contributions under the same terms.
