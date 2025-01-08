{
  inputs = {
    # keep-sorted start block=yes case=no
    flake-utils = {
      inputs.systems.follows = "systems";
      url = "github:numtide/flake-utils";
    };
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    pre-commit-hooks = {
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
      url = "github:cachix/pre-commit-hooks.nix";
    };
    systems.url = "github:nix-systems/default";
    treefmt-nix = {
      inputs.nixpkgs.follows = "nixpkgs";
      url = "github:numtide/treefmt-nix";
    };
    # keep-sorted end
  };

  outputs =
    inputs@{
      nixpkgs,
      self,
      ...
    }:
    let
      arch = [
        "x86_64-linux"
        "aarch64-linux"
      ];
    in
    inputs.flake-utils.lib.eachSystem arch (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
        };
        treefmtEval = inputs.treefmt-nix.lib.evalModule pkgs (
          { pkgs, ... }:
          {
            # keep-sorted start block=yes
            programs.jsonfmt = {
              enable = true;
              package = pkgs.jsonfmt;
            };
            programs.keep-sorted.enable = true;
            programs.nixfmt = {
              enable = true;
              package = pkgs.nixfmt-rfc-style;
            };
            programs.yamlfmt.enable = true;
            projectRootFile = "flake.nix";
            settings.formatter = {
              # keep-sorted start block=yes
              actionlint = {
                command = pkgs.actionlint;
                includes = [ "./.github/workflows/*.yml" ];
              };
              jsonfmt.includes = [
                "*.json"
                "./.github/*.json"
                "./.vscode/*.json"
              ];
              yamlfmt.excludes = [
                "*.sops.*"
                "clusters/titania/secrets/*"
                "base/fluxcd/gotk-components.yml"
              ];
              yamlfmt.includes = [
                "*.yml"
                "*.yaml"
              ];
              # keep-sorted end
            };
            # keep-sorted end
          }
        );
        env = {
          ZARF_CONFIG = "$(${pkgs.git}/bin/git rev-parse --show-toplevel)/config/zarf-config.yaml";
        };
      in
      {
        checks.pre-commit-check = inputs.pre-commit-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            # keep-sorted start case=no
            check-executables-have-shebangs.enable = true;
            check-shebang-scripts-are-executable.enable = true;
            detect-private-keys.enable = true;
            end-of-file-fixer.enable = true;
            nixfmt-rfc-style.enable = true;
            trim-trailing-whitespace.enable = true;
            # keep-sorted end
          };
        };
        devShells.default = nixpkgs.legacyPackages.${system}.mkShell {
          shellHook =
            self.checks.${system}.pre-commit-check.shellHook
            + "\n"
            + (builtins.concatStringsSep "\n" (
              pkgs.lib.attrsets.mapAttrsToList (k: v: "export ${k}=${v}") env
            ));
          buildInputs = with pkgs; [
            gh
          ];
        };
        formatter = treefmtEval.config.build.wrapper;
      }
    );
}
