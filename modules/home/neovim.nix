{ pkgs, ... }:
let
  treesitter = pkgs.vimPlugins.nvim-treesitter.withPlugins (
    p: with p; [
      bash
      c
      cpp
      css
      diff
      dockerfile
      gitcommit
      go
      html
      javascript
      json
      lua
      luadoc
      make
      markdown
      markdown_inline
      nix
      python
      query
      regex
      rust
      sql
      toml
      tsx
      typescript
      vim
      vimdoc
      yaml
    ]
  );
in
{
  programs.neovim = {
    enable = true;
    defaultEditor = false;
    viAlias = true;
    vimAlias = true;
    vimdiffAlias = true;
    initLua = ''
      require("config")
    '';

    plugins = with pkgs.vimPlugins; [
      plenary-nvim
      telescope-nvim

      treesitter

      nvim-lspconfig
      nvim-cmp
      cmp-nvim-lsp
      cmp-nvim-lsp-signature-help
      cmp-buffer
      cmp-path
      cmp-cmdline
      luasnip
      cmp_luasnip
      friendly-snippets

      nvim-web-devicons
      lualine-nvim
      bufferline-nvim
      which-key-nvim
      nvim-notify
      indent-blankline-nvim
      nvim-autopairs
      nvim-surround
      comment-nvim
      alpha-nvim
      persistence-nvim
      tiny-inline-diagnostic-nvim

      gitsigns-nvim
      neogit

      oil-nvim
      neo-tree-nvim
      nui-nvim
      trouble-nvim

      toggleterm-nvim

      conform-nvim
      nvim-lint
    ];

    extraPackages = with pkgs; [
      nil
      nixfmt
      lua-language-server
      stylua
      bash-language-server
      shellcheck
      shfmt
      basedpyright
      ruff
      gopls
      rust-analyzer
      clang-tools
      typescript-language-server
      vscode-langservers-extracted
      prettier
      marksman
      taplo
      yaml-language-server
      dockerfile-language-server
      ripgrep
      fd
    ];
  };
}
