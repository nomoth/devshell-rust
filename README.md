### Usage
```
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    devshell-rust.url = "github:nomoth/devshell-rust";
  };

  outputs = { nixpkgs, devshell-rust, ... }: {
    devShells.x86_64-linux.default = devshell-rust.lib.mkRustShell {
      system = "x86_64-linux";
      rustVersion = "1.75.0";
      extraPackages = with (import nixpkgs { system = "x86_64-linux"; }); [
        openssl
        sqlite
      ];
    };
  };
}
```

### Manual update in your project
```bash
nix flake lock --update-input devshell-rust
```
