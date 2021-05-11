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
            url = https://github.com/sjsch/interactive-cek-machine/archive/e671383bbcc72b8fca8b245235f92d2edd6e0ae1.tar.gz;
            sha256 = "1n8l81488phawdil1naidx0csl0q885zh56ml482ry314jmhzzhi";
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
