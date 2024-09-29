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
        # jupyter
        jupyter = pkgs.jupyter.override {
          definitions = {
            clojure = pkgs.clojupyter.definition;
            python_torch =
              let
                # python_torch = (builtins.head pkgs.python_torch.nativeBuildInputs);
                python_torch = pkgs.python3.withPackages (ps: with ps; [ ]);
              in
              {
                displayName = "PyTorch";
                language = "python";
                logo32 = "${pkgs.jupyter.sitePackages}/ipykernel/resources/logo-32x32.png";
                logo64 = "${pkgs.jupyter.sitePackages}/ipykernel/resources/logo-64x64.png";
                argv = [
                  "${python_torch}/bin/python"
                  "-m"
                  "ipykernel_launcher"
                  "-f"
                  "{connection_file}"
                ];
              };
          };
        };
        # quarto
        # quarto = pkgs.quarto.override { python3 = jupyter; };
        quarto = (pkgs.quarto.override { python3 = null; }).overrideAttrs (
          final: prev: {
            preFixup =
              with builtins;
              let
                pfix = prev.preFixup;
                plen = (stringLength pfix);
                pfix_sub = substring 0 (plen - 1) pfix;
              in
              # (substring 0  prev.preFixup)
              # prev.preFixup + "--prefix QUARTO_PYTHON : ${jupyter}/bin/python3";
              pfix_sub + "--prefix QUARTO_PYTHON : ${jupyter}/bin/python3";
          }
        );
        # blog
        blog = pkgs.stdenv.mkDerivation {
          name = "blog";
          src = ./blog;
          buildInputs = [
            pkgs.quarto
            jupyter
          ];
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
        devShells.default = pkgs.mkShell {
          buildInputs = [
            quarto
            jupyter
          ];
        };
        packages = rec {
          inherit blog quarto;
          default = blog;
        };
      }
    );
}
