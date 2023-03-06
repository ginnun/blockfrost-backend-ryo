{
  description = "Blockfrost API backend";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/release-22.11";

  outputs = { self, nixpkgs }:
    let
      lib = nixpkgs.lib;
      supportedSystems = [ "x86_64-linux" ];
      forAllSystems = f: lib.genAttrs supportedSystems (system: f system);
      legacyPkgs = nixpkgs.legacyPackages;
      default = lib.genAttrs supportedSystems (system: import ./default.nix {
        inherit system;
        pkgs = legacyPkgs.${system};
      });
      shell = lib.genAttrs supportedSystems (system: import ./shell.nix {
        inherit system;
        pkgs = legacyPkgs.${system};
      });
    in
    {
      packages = forAllSystems (system: {
        inherit (default.${system}) blockfrost-backend-ryo;
        dockerImage = legacyPkgs.${system}.dockerTools.buildImage {
          name = "blockfrost";
          runAsRoot = ''
            #!${legacyPkgs.${system}.runtimeShell}
            mkdir -p /app
            cp -a ${self.packages.${system}.blockfrost-backend-ryo}/libexec/source/config /app/config
          '';
          config = {
            Cmd = [ "${self.packages.${system}.blockfrost-backend-ryo}/bin/blockfrost-backend-ryo" ];
            WorkingDir = "/app";
          };
        };
        default = self.packages.${system}.blockfrost-backend-ryo;
      });
      checks = forAllSystems (system: {
        inherit (self.packages.${system}) blockfrost-backend-ryo dockerImage;
      });
      devshells = forAllSystems (system: {
        default = shell.${system};
      });
      apps = forAllSystems (system: {
        blockfrost-backend-ryo = {
          type = "app";
          program = "${self.packages.${system}.blockfrost-backend-ryo}/bin/blockfrost-backend-ryo";
        };
        default = self.apps.${system}.blockfrost-backend-ryo;
      });
      overlays.default = self: super: {
        inherit (self.packages.${super.system}) blockfrost-backend;
      };
    };
}