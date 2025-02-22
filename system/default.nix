{
  lib,
  pkgs,
  config,
  ...
}:
{
  imports = [
    ./boot/boot.nix
    ./boot/specialisations.nix
    ./disk/btrfs.nix
    ./disk/impermanence.nix
    ./extra
    ./runtime
    ./server
    ./session/niri.nix
    ./startup/agenix.nix
    ./startup/auth.nix
    ./startup/users.nix
    ./backup.nix
    ./docker.nix
    ./gh.nix
    ./nix.nix
    ./style.nix
  ];

  options.custom = with lib; {
    shell = {
      packages = mkOption {
        type =
          with types;
          attrsOf (oneOf [
            str
            attrs
            package
          ]);
        apply = custom.mkShellPackages;
        default = { };
        description = ''
          Attrset of shell packages to install and add to pkgs.custom overlay (for compatibility across multiple shells).
          Both string and attr values will be passed as arguments to writeShellApplicationCompletions
        '';
        example = ''
          shell.packages = {
            myPackage1 = "echo 'Hello, World!'";
            myPackage2 = {
              runtimeInputs = [ pkgs.hello ];
              text = "hello --greeting 'Hi'";
            };
          }
        '';
      };
    };
    symlinks = mkOption {
      type = types.attrsOf types.str;
      default = { };
      description = "Symlinks to create in the format { dest = src;}";
    };
  };

  config = {
    # don’t shutdown when power button is short-pressed
    services.logind.extraConfig = "HandlePowerKey=ignore";

    # automount disks
    services.gvfs.enable = true;
    # services.devmon.enable = true;
    programs = {
      dconf.enable = true;
      seahorse.enable = true;
    };

    environment = {
      etc = {
        # universal git settings
        "gitconfig".text = config.hm.xdg.configFile."git/config".text;
      };

      # install fish completions for fish
      # https://github.com/nix-community/home-manager/pull/2408
      pathsToLink = [ "/share/fish" ];

      variables = {
        TERMINAL = lib.getExe config.hm.custom.terminal.package;
        EDITOR = "nvim";
        VISUAL = "nvim";
        NIXPKGS_ALLOW_UNFREE = "1";
        STARSHIP_CONFIG = "${config.hm.xdg.configHome}/starship.toml";
      };

      # use some shell aliases from home manager
      shellAliases =
        {
          inherit (config.hm.programs.bash.shellAliases)
            eza
            ls
            ll
            la
            lla
            ;
        }
        // {
          inherit (config.hm.home.shellAliases)
            t # eza related
            y # yazi
            ;
        };
      systemPackages = with pkgs; [
        curl
        eza
        (lib.hiPrio procps) # for uptime
        neovim
        ripgrep
        yazi
        zoxide
      ]
      # add custom user created shell packages
      ++ (lib.attrValues config.custom.shell.packages)
      ++ (lib.optional config.hm.custom.helix.enable helix);
    };

    # add custom user created shell packages to pkgs.custom.shell
    nixpkgs.overlays = [
      (_: prev: {
        custom = prev.custom // {
          shell = config.custom.shell.packages // config.hm.custom.shell.packages;
        };
      })
    ];

    # create symlink to dotfiles from default /etc/nixos
    custom.symlinks = {
      "/etc/nixos" = "/persist${config.hm.home.homeDirectory}/projects/wolborg";
    };

    # create symlinks
    systemd.tmpfiles.rules = [
      # cleanup systemd coredumps once a week
      "D! /var/lib/systemd/coredump root root 7d"
    ] ++ (lib.mapAttrsToList (dest: src: "L+ ${dest} - - - - ${src}") config.custom.symlinks);

    # setup fonts
    fonts = {
      enableDefaultPackages = true;
      inherit (config.hm.custom.fonts) packages;
    };

    programs = {
      # use same config as home-manager
      bash.interactiveShellInit = config.hm.programs.bash.initExtra;

      file-roller.enable = true;

      # remove nano
      nano.enable = lib.mkForce false;
    };

    xdg = {
      # use mimetypes defined from home-manager
      mime =
        let
          hmMime = config.hm.xdg.mimeApps;
        in
        {
          enable = true;
          inherit (hmMime) defaultApplications;
          addedAssociations = hmMime.associations.added;
          removedAssociations = hmMime.associations.removed;
        };

      # fix opening terminal for nemo / thunar by using xdg-terminal-exec spec
      terminal-exec = {
        enable = true;
        settings = {
          default = [ "${config.hm.custom.terminal.package.pname}.desktop" ];
        };
      };
    };

    custom.persist = {
      root.directories = lib.optionals config.hm.custom.wifi.enable [
        "/etc/NetworkManager"
      ];
      root.cache.directories = [
        "/var/lib/systemd/coredump"
      ];

      home.directories = [ ".local/state/wireplumber" ];
    };
  };
}
