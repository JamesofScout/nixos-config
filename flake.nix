{
  inputs = {
    nixpkgs.url = "github:NixOs/nixpkgs";
    hyprland-contrib.url = "github:hyprwm/contrib";
    home-manager.url = "github:nix-community/home-manager";
    stylix.url = "github:danth/stylix";
    nixvim = {
      url = "github:nix-community/nixvim";
    };
    nix-tun.url = "github:nix-tun/nixos-modules/container-utils";
    sops-nix.url = "github:Mic92/sops-nix";
    flake-utils.url = "github:numtide/flake-utils";
    nix-index-database.url = "github:nix-community/nix-index-database";
    impermanence.url = "github:nix-community/impermanence";
    disko.url = "github:nix-community/disko";
    nixos-cosmic = {
      url = "github:lilyinstarlight/nixos-cosmic";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { nixpkgs
    , ...
    } @ inputs: {
      nixosConfigurations.Kakariko = nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";
        modules = [
          {
            nix.settings = {
              substituters = [ "https://cosmic.cachix.org/" ];
              trusted-public-keys = [ "cosmic.cachix.org-1:Dya9IyXD4xdBehWjrkPv6rtxpmMdRel02smYzA85dPE=" ];
            };
          }
          inputs.nix-tun.nixosModules.nix-tun
          inputs.nixos-cosmic.nixosModules.default
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
          specialArgs = { inherit inputs; };
        };
    };
}
