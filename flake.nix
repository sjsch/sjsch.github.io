{
  description = "Build my blog";

  inputs.nixpkgs.follows = "haskellNix/nixpkgs-unstable";
  inputs.haskellNix.url = "github:input-output-hk/haskell.nix";

  outputs = { self, nixpkgs, haskellNix }: {
    packages.x86_64-linux.sjsch-blog =
      let
        overlays = [
          haskellNix.overlay
          (final: prev: {
            sjsch-site =
              final.haskell-nix.project' {
                src = ./.;
                compiler-nix-name = "ghc8104";
              };
          })
        ];

        pkgs = import nixpkgs { system = "x86_64-linux"; inherit overlays; };

        cekMachine = import
          (fetchTarball {
            url = https://github.com/sjsch/interactive-cek-machine/archive/dd80e3c5c4dfac7d6698663a540c92b68cb0298c.tar.gz;
            sha256 = "01xdy29smpmv000gbhmswkqmj0cls9gc397mvbn4qfdnra42kf18";
          })
          { inherit pkgs; };

        flake = pkgs.sjsch-site.flake { };

      in

      pkgs.stdenv.mkDerivation {
        name = "sjsch-blog";
        version = "dev";

        src = ./.;

        nativeBuildInputs = [ flake.packages."sjsch-site:exe:sjsch-site" ];

        buildPhase = ''
          sjsch-site build
          mkdir -p _site/scripts
          cp ${cekMachine} _site/scripts/cek.js
        '';

        installPhase = ''
          mv _site $out
        '';
      };

    defaultPackage.x86_64-linux = self.packages.x86_64-linux.sjsch-blog;
  };
}
