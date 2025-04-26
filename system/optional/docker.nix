{
  lib,
  pkgs,
  config,
  ...
}:
{
  options.custom = with lib; {
    distrobox.enable = mkEnableOption "Enable distrobox";
    docker.enable = mkEnableOption "Enable docker" // {
      default = config.custom.distrobox.enable;
    };
  };

  config = lib.mkIf config.custom.docker.enable {
    environment.systemPackages = lib.mkIf config.custom.distrobox.enable [ pkgs.distrobox ];

    virtualisation = {
      podman = {
        enable = true;
        # create a `docker` alias for podman, to use it as a drop-in replacement
        dockerCompat = true;
        # required for containers under podman-compose to be able to talk to each other.
        defaultNetwork.settings.dns_enabled = true;
      };
    };

    # store docker images on /cache
    hm.custom.persist = {
      home.cache = {
        directories = [ ".local/share/containers" ];
      };
    };
  };
}
