{
  inputs = {
    nixpkgs.url = github:NixOS/nixpkgs/nixpkgs-unstable;
    purs-nix.url = github:purs-nix/purs-nix;
    utils.url = github:ursi/flake-utils;
    hooks.url = github:cachix/git-hooks.nix;
    ps-tools.follows = "purs-nix/ps-tools";
  };

  outputs = { self, utils, ... }@inputs:
    let
      linux = "linux";
      x64 = "x86_64";
      linux-x64 = "${x64}-${linux}";
      # TODO add missing arm to match standard systems
      #  right now purs-nix is only compatible with x86_64-linux
      platform = x64;
      os = linux;
      systems = [ "${platform}-${os}" ];
    in
    utils.apply-systems
      { inherit inputs systems; }
      ({ system, pkgs, ps-tools, ... }:
        let
          inherit (ps-tools.for-0_15) purescript purs-tidy purescript-language-server;
          nodejs = pkgs.runCommand
            "nodejs-flags"
            {
              inherit (pkgs.nodejs) meta version src;
              nativeBuildInputs = [ pkgs.makeWrapper ];
              NODE_OPTIONS = "--experimental-import-meta-resolve";
            }
            ''
              cp -r --no-preserve=ownership --reflink=auto ${pkgs.nodejs} $out
              chmod -R +w $out
              wrapProgram $out/bin/node --set NODE_OPTIONS $NODE_OPTIONS
            '';
          purs-nix = inputs.purs-nix { inherit system; };
          ps = purs-nix.purs
            {
              # Project dir (src, test)
              dir = ./.;
              # Dependencies
              dependencies =
                with purs-nix.ps-pkgs;
                [
                  debug
                  prelude
                  console
                  effect
                ];
              # compiler
              inherit purescript nodejs;
            };
          ps-command = ps.command { };
          purs-watch = pkgs.writeShellApplication {
            name = "purs-watch";
            runtimeInputs = with pkgs; [ entr ps-command ];
            text = ''find src | entr -s "purs-nix $*"'';
          };
          concurrent = pkgs.writeShellApplication {
            name = "concurrent";
            runtimeInputs = with pkgs; [
              concurrently
            ];
            text = ''
              concurrently\
                --color "auto"\
                --prefix "[{command}]"\
                --handle-input\
                --restart-tries 10\
                "$@"
            '';
          };
          devRuntimeInputs = with pkgs; [
            purs-watch
            concurrent
            temporalite
          ];
          dev = pkgs.writeShellApplication {
            name = "dev";
            runtimeInputs = devRuntimeInputs;
            text = ''concurrent \
              "purs-watch run"\
              "temporalite start --namespace default"
            '';
          };
          dev-debug = pkgs.writeShellApplication {
            name = "dev-debug";
            runtimeInputs = devRuntimeInputs ++ [ ps-command ];
            text = ''concurrent \
              "TEMPORAL_DEBUG=1 NODE_OPTIONS=--inspect-brk purs-nix run"\
              "temporalite start --namespace default"
            '';
          };
          # helpers
          hooks = inputs.hooks.lib.${system}.run {
            src = ./frontend;
            hooks = {
              # hook for frontend
              purs-tidy = {
                enable = true;
                package = purs-tidy;
              };
            };
          };
        in
        {
          apps.default =
            {
              type = "app";
              program = "${self.packages.${system}.default}";
            };

          packages =
            with ps;
            {
              default = pkgs.writeScript "arbitralis" ''
                #!${nodejs}/bin/node
                import("${self.packages.${system}.output}/Main/index.js").then(m=>m.main())
              '';
              output = output { };
            };

          devShells.default = pkgs.mkShell {
            packages =
              devRuntimeInputs
              ++ [
                ps-command
                dev
                dev-debug
                purescript
                purs-tidy
                purescript-language-server
                nodejs
              ];
              shellHook = ''
                ${hooks.shellHook}
                shopt -s expand_aliases
                alias log_='printf "\033[1;32m%s\033[0m\n" "$@"'
                alias info_='printf "\033[1;34m[INFO] %s\033[0m\n" "$@"'
                alias warn_='printf "\033[1;33m[WARN] %s\033[0m\n" "$@"'

                log_ "Welcome to Arbitralis shell."
                info_ "Available commands: dev, dev-debug."
              '';
          };
        });

  # --- Flake Local Nix Configuration ----------------------------
  nixConfig = {
    accept-flake-config = true;
    extra-experimental-features = "nix-command flakes";
  };
}
