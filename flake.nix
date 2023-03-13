{
  description = "A library for datatype-generic programming in Agda";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-22.11";
    utils.url = "github:numtide/flake-utils";
    agda-stdlib-src = {
      # url = "github:agda/agda-stdlib/v1.7.1";
      url = "github:agda/agda-stdlib";
      flake = false;
    };
  };

  outputs = { self, nixpkgs, utils, agda-stdlib-src }:
    utils.lib.eachDefaultSystem (system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        agda-stdlib = pkgs.agdaPackages.standard-library.overrideAttrs (_: {
          version = "1.7.1";
          src = agda-stdlib-src;
        });
        agdaWithStandardLibrary = pkgs.agda.withPackages (p: [
          agda-stdlib
        ]);

      in {
        devShell = pkgs.mkShell {
          buildInputs = [
            agdaWithStandardLibrary
            pkgs.graphviz
          ];
        };

        packages.default = pkgs.agdaPackages.mkDerivation {
          pname = "generics";
          version = "1.0.0";
          src = ./.;

          buildInputs = [
            agda-stdlib
          ];

          meta = with pkgs.lib; {
            description = "A library for datatype-generic programming in Agda";
            homepage = "https://github.com/flupe/generics";
            license = licenses.mit;
            # platforms = platforms.unix;
            # maintainers = with maintainers; [ ];
          };
        };
      }
    );
}
