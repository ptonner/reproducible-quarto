{
  description = "Reproducible blog with Quarto";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs =
    {
      self,
      nixpkgs,
      flake-utils,
    }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        blog = pkgs.stdenv.mkDerivation {
          name = "blog";
          src = ./blog;
          buildInputs = [ pkgs.quarto ];
          buildPhase = ''
            # Deno needs to add stuff to $HOME/.cache
            # so we give it a home to do this
            mkdir home
            export HOME=$PWD/home

            quarto render
          '';
          installPhase = ''
            mkdir -p $out
            cp -r _site $out/
          '';
        };
      in
      {
        devShells.default = pkgs.mkShell { buildInputs = with pkgs; [ quarto ]; };
        packages = rec {
          inherit blog;
          default = blog;
        };
      }
    );
}
