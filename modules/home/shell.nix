{
  config,
  lib,
  pkgs,
  ...
}:
let
  homeDir = config.home.homeDirectory;
in
{
  programs.zsh = {
    enable = true;

    oh-my-zsh = {
      enable = true;
      theme = "gentoo";
      plugins = [
        "git"
        "docker"
        "docker-compose"
        "kubectl"
        "terraform"
        "aws"
        "gcloud"
        "azure"
        "ansible"
        "python"
        "pip"
        "node"
        "npm"
        "yarn"
        "golang"
        "rust"
        "sudo"
        "extract"
        "z"
        "history"
        "command-not-found"
        "vscode"
      ];
    };

    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;

    history.path = "/dev/null";

    initContent = ''
      if [ -r "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions/zsh-fast-syntax-highlighting.plugin.zsh" ]; then
        source "${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions/zsh-fast-syntax-highlighting.plugin.zsh"
      fi

      export PATH="$PATH:$HOME/.spicetify"

      [ -f "$HOME/.cargo/env" ] && . "$HOME/.cargo/env"

      export GOPATH="$HOME/.go"
      export PATH="$GOPATH/bin:$HOME/.local/bin:$PATH"

      export MAKEFLAGS="-j8"
      export MUTTER_DEBUG_FORCE_KMS_MODE=simple

      export PATH="$HOME/.kimi-code/bin:$HOME/.opencode/bin:$HOME/.lmstudio/bin:$PATH"
      export PATH="$PATH:$HOME/go/bin:$HOME/.local/bin:$HOME/.cargo/bin"
      export PATH="$PATH:$HOME/.pdtm/go/bin"
      export PATH="$PATH:$HOME/.kubescape/bin"

      export PNPM_HOME="$HOME/.local/share/pnpm"
      export BUN_INSTALL="$HOME/.bun"
      case ":$PATH:" in
        *":$PNPM_HOME:"*) ;;
        *) export PATH="$PNPM_HOME:$PATH" ;;
      esac
      [ -s "$BUN_INSTALL/_bun" ] && source "$BUN_INSTALL/_bun"

      mkcd() {
        mkdir -p "$1" && cd "$1"
      }
    '';

    shellAliases = {
      ls = "ls -lt";
      ll = "ls -lah";
      la = "ls -A";
      ".." = "cd ..";
      "..." = "cd ../..";
      "...." = "cd ../../..";
      c = "clear";
      reload = "source ~/.config/zsh/.zshrc";

      update = "nix flake update --flake $HOME/Flakes && sudo nixos-rebuild switch --flake $HOME/Flakes#$(hostname -s)";
      install = "nix profile install";
      remove = "nix profile remove";
      search = "nix search nixpkgs";

      cat = "bat";
      b = "bat";
      grep = "rg";

      h = "history";
      q = "exit";

      df = "df -h";
      free = "free -h";
      ports = "ss -tulpn";
      myip = "curl -s ifconfig.me && echo";
      psg = "ps aux | rg -i";

      untar = "tar -xvf";
      targz = "tar -czvf";

      cp = "cp -i";
      mv = "mv -i";
      rm = "trash-put -v";

      tree = "tree -C";

      g = "git";
      gs = "git status";
      ga = "git add";
      gaa = "git add .";
      gc = "git commit";
      gcm = "git commit -m";
      gp = "git push";
      gl = "git pull";
      gd = "git diff";
      gds = "git diff --staged";
      gb = "git branch";
      gco = "git checkout";
      glog = "git log --oneline --graph --decorate --all";

      cr = "cargo run";
      cb = "cargo build";
      ct = "cargo test";
      cc = "cargo check";
      crr = "cargo run --release";
      cbr = "cargo build --release";
    };
  };

  home.sessionVariables = {
    EDITOR = "micro";
    VISUAL = "micro";
    MICRO_TRUECOLOR = "1";
  };

  home.sessionPath = [
    "$HOME/.local/share/pnpm"
    "$HOME/.bun/bin"
    "$HOME/go/bin"
    "$HOME/.spicetify"
  ];

  home.packages = [ pkgs.zsh-fast-syntax-highlighting ];
}
