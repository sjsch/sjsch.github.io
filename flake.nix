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
            url = https://github.com/sjsch/interactive-cek-machine/archive/803c9bd01f6d30a641243e4cb0747a70818e0f13.tar.gz;
            sha256 = "1wzwmxfw1d4z4c19mkksxcfk93p747f3kbscn45bph6pr92rd3sb";
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
