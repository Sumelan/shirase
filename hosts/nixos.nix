{
  lib,
  inputs,
  specialArgs,
  user,
  ...
}@args:
let
  mkNixosConfiguration = 
    host:
    {
      pkgs ? args.pkgs,
    }:
    lib.nixosSystem {
      inherit pkgs;

    specialArgs = specialArgs // {
      inherit host user;
      isLaptop = host == "acer";
      dotfiles = "/persist/home/${user}/projects/wolborg";
    };
    modules = [
      ./${host} # host specific configuration
      ./${host}/hardware.nix  # host specific hardware configuration
      ../system # system modules
      ../overlays
      inputs.home-manager.nixosModules.home-manager
      {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;

          extraSpecialArgs = specialArgs // {
            inherit host user;
            isLaptop = host == "acer";
            wallpapers = {
              "HDMI-A-1" = {
                path = ./sakura/wallpaper-1.png;
                convertMethod = "lutgen"; # gonord, lutgen, none
              };
              "DP-1" = {
                path = ./sakura/wallpaper-2.png;
                convertMethod = "lutgen"; # gonord, lutgen, none
              };
              "eDP-1" = {
                path = ./acer/wallpaper.png;
                convertMethod = "gonord"; # gonord, lutgen, none
              };
            };
            dotfiles = "/persist/home/${user}/projects/wolborg";
          };
          users.${user} = {
            imports = [
              ./${host}/home.nix  # host specific home-manager configuration
              ../home-manager # home-manager modules
              inputs.nix-index-database.hmModules.nix-index
              inputs.spicetify-nix.homeManagerModules.default
              inputs.nvf.homeManagerModules.default
            ];
          };
        };
      }
      # alias for home-manager
      (lib.mkAliasOptionModule [ "hm" ] [ "home-manager" "users" user ])
      inputs.stylix.nixosModules.stylix
      inputs.niri.nixosModules.niri
      inputs.impermanence.nixosModules.impermanence
      inputs.agenix.nixosModules.default
    ];
  };
in
{
  acer = mkNixosConfiguration "acer" { };
  sakura = mkNixosConfiguration "sakura"{ };
}
