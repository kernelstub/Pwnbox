## What this PR does

Describe the change and why it is needed.

## Checks

- [ ] `nixfmt --check` passes on every changed `.nix` file
- [ ] `bash -n dotfiles/scripts/pwnbox-theme scripts/*.sh` passes if a script changed
- [ ] The system still evaluates (build the host you changed, or at least
      `nix flake check`)
- [ ] Docs updated where behaviour changed
- [ ] No emojis in code, docs or the commit message
- [ ] Generated files are not committed (only their bases)

## Related issues

Closes #
