{
  description = "ShojiWM - The most customizable Wayland compositor with TypeScript";

  nixConfig = {
    extra-substituters = [ "https://shojivm.cachix.org" ];
    extra-trusted-public-keys = [ "shojivm.cachix.org-1:yO9nqUqUs/81UQ9Ynx7XF0DKhESvJAGB3Q1ZO/OTjao=" ];
  };

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
    in {
      packages.${system} = {
        shojiwm = pkgs.callPackage ./package.nix { };
        default = self.packages.${system}.shojiwm;
      };

      nixosModules.shojiwm = import ./module.nix;
      nixosModules.default = self.nixosModules.shojiwm;
    };
}
