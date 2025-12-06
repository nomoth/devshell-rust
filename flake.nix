{
  description = "Rust development shell template";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = { self, nixpkgs, rust-overlay }:
    let
      forAllSystems = nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
    in {
      lib = {
        mkRustShell = { system, rustVersion ? "stable", extraPackages ? [ ] }:
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ rust-overlay.overlays.default ];
            };
          in pkgs.mkShell {
            buildInputs = with pkgs;
              [
                (rust-bin.${rustVersion}.latest.default.override {
                  extensions = [ "rust-src" "rust-analyzer" ];
                })
                pkg-config
              ] ++ extraPackages;

            RUST_BACKTRACE = 1;
          };
      };

      checks = forAllSystems (system:
        let shell = self.devShells.${system}.default;
        in {
          # Test simple : le devshell se build
          devshell-builds = shell.overrideAttrs (old: {
            phases = [ "installPhase" ];
            installPhase = ''
              # Vérifier que les outils essentiels existent
              command -v cargo >/dev/null || exit 1
              command -v rustc >/dev/null || exit 1
              command -v rust-analyzer >/dev/null || exit 1

              # Vérifier les versions
              cargo --version
              rustc --version

              touch $out
            '';
          });
        });

      # Devshell par défaut pour tester
      devShells = forAllSystems
        (system: { default = self.lib.mkRustShell { inherit system; }; });
    };
}
