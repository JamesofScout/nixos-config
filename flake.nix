{
  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs";
    hyprland-contrib.url = "github:hyprwm/contrib";
    home-manager.url = "github:nix-community/home-manager";
    stylix.url = "github:danth/stylix";
    easyroam-nixpkgs.url = "github:NixOs/nixpkgs/f45b52f30f082f40bef75e18a9e17dec93657f47";
    nixvim = {
      url = "github:nix-community/nixvim";
    };
    nix-tun.url = "github:nix-tun/nixos-modules/container-utils";
    sops-nix.url = "github:Mic92/sops-nix";
    flake-utils.url = "github:numtide/flake-utils";
    nix-index-database.url = "github:nix-community/nix-index-database";
    impermanence.url = "github:nix-community/impermanence";
    disko.url = "github:nix-community/disko";
  };

  outputs =
    { nixpkgs
    , ...
    } @ inp:
    let
      inputs = inp // { flake-root = ./.; };
    in
    {
      nixosConfigurations.Kakariko = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          inputs.nix-tun.nixosModules.nix-tun
          ./hosts/kakariko/configuration.nix
          ./hosts/kakariko/hardware-configuration.nix
          ./hosts/kakariko/boot.nix
          inputs.home-manager.nixosModules.home-manager
        ];
        specialArgs = { inherit inputs; };
      };

      nixosConfigurations.Hateno = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          inputs.home-manager.nixosModules.home-manager
          ./hosts/hateno/configuration.nix
          ./modules/modules.nix
          ./hosts/hateno/hardware-configuration.nix
        ];
        specialArgs = { inherit inputs; };
      };

      nixosConfigurations.HyruleCity = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          ./hosts/hyrule-city/configuration.nix
          ./hosts/hyrule-city/hardware-configuration.nix
          ./hosts/hyrule-city/nvidia-config.nix
          ./hosts/hyrule-city/boot.nix
          ./hosts/hyrule-city/steam.nix
          inputs.home-manager.nixosModules.home-manager
        ];
        specialArgs = { inherit inputs; };
      };

      nixosConfigurations.stick = nixpkgs.lib.nixosSystem {
        specialArgs = { inherit inputs; };
        modules = [
          inputs.disko.nixosModules.disko
          inputs.home-manager.nixosModules.home-manager
          ./hosts/stick/configuration.nix
          ./modules/modules.nix
        ];
      };

      formatter.x86_64-linux = nixpkgs.legacyPackages.x86_64-linux.alejandra;

      devShells."x86_64-linux".default = with import nixpkgs { system = "x86_64-linux"; };
        mkShell {
          sopsPGPKeyDirs = [
            "${toString ./.}/keys/hosts"
            "${toString ./.}/keys/users"
          ];
        };
    };
}
