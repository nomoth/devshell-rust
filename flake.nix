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
        # Version simple: 95% des cas d'usage
        mkRustShell = { system, channel ? "stable", version ? "latest"
          , extraPackages ? [ ] }:
          self.lib.mkRustShellAdvanced {
            inherit system channel version extraPackages;
          };

        # Version avancée: tous les cas d'usage
        mkRustShellAdvanced = { system, channel ? "stable", version ? "latest"
          , extraPackages ? [ ], targets ? [ ], extensions ? [ "rust-src" "rust-analyzer" ]
          , rustFlags ? null, envVars ? { } }:
          let
            pkgs = import nixpkgs {
              inherit system;
              overlays = [ rust-overlay.overlays.default ];
            };

            rustToolchain = if channel == "nightly" then
              pkgs.rust-bin.nightly.${version}.default
            else if channel == "beta" then
              pkgs.rust-bin.beta.${version}.default
            else
              pkgs.rust-bin.stable.${version}.default;

            # Variables d'environnement par défaut
            defaultEnvVars = {
              RUST_BACKTRACE = 1;
            };

            # Merge des variables d'environnement
            allEnvVars = defaultEnvVars // envVars
              // (if rustFlags != null then { RUSTFLAGS = rustFlags; } else { });

          in pkgs.mkShell ({
            buildInputs = [
              (rustToolchain.override { inherit extensions targets; })
              pkgs.pkg-config
            ] ++ extraPackages;
          } // allEnvVars);
      };

      checks = forAllSystems (system:
        let 
          # Test de la version simple
          shellSimple = self.devShells.${system}.default;
          
          # Test de la version avancée avec wasm
          shellWasm = self.lib.mkRustShellAdvanced {
            inherit system;
            targets = [ "wasm32-unknown-unknown" ];
          };
        in {
          devshell-simple-builds = shellSimple.overrideAttrs (old: {
            phases = [ "installPhase" ];
            installPhase = ''
              command -v cargo >/dev/null || exit 1
              command -v rustc >/dev/null || exit 1
              command -v rust-analyzer >/dev/null || exit 1
              cargo --version
              rustc --version
              touch $out
            '';
          });
          
          devshell-wasm-builds = shellWasm.overrideAttrs (old: {
            phases = [ "installPhase" ];
            installPhase = ''
              # Vérifier que wasm32 est disponible
              rustc --print target-list | grep wasm32-unknown-unknown || exit 1
              touch $out
            '';
          });
        });

      # Devshell par défaut pour tester
      devShells = forAllSystems
        (system: { default = self.lib.mkRustShell { inherit system; }; });
    };
}
