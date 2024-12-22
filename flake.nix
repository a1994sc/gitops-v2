{
  inputs = {
    flake-utils.url = "github:numtide/flake-utils";
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
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
    in inputs.flake-utils.lib.eachSystem arch (system:
    let
      pkgs = import nixpkgs {
        inherit system;
      };
    in
    {
      devShells.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          jsonnet
        ];
      };
    }
  );
}
