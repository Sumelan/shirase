{ pkgs, ... }:
let
  inherit (pkgs) lib callPackage;
  # injects a source parameter from nvfetcher
  # adapted from viperML's config
  # https://github.com/viperML/dotfiles/blob/master/packages/default.nix
  w =
    _callPackage: path: extraOverrides:
    let
      sources = pkgs.callPackages (path + "/generated.nix") { };
      firstSource = lib.head (lib.attrValues sources);
    in
    _callPackage (path + "/default.nix") (
      extraOverrides // { source = lib.filterAttrs (k: _: !(lib.hasPrefix "override" k)) firstSource; }
    );
  repo_url = "https://raw.githubusercontent.com/Sumelan/wolborg";
in
rec {
  default = install;

  install = pkgs.writeShellApplication {
    name = "sumelan-install";
    runtimeInputs = [ pkgs.curl ];
    text = "sh <(curl -L ${repo_url}/main/install.sh)";
  };

  # for nixos-rebuild
  hsw = callPackage ./hsw { };
  nsw = callPackage ./nsw { };

  # custom tela built with catppucin variant colors
  tela-dynamic-icon-theme = callPackage ./tela-dynamic-icon-theme { };

  fuzzel-scripts = callPackage ./fuzzel-scripts { };

  niricast = callPackage ./niricast { };

  vv =
    assert (lib.assertMsg (!(pkgs ? "vv")) "vv: vv is in nixpkgs");
    (w callPackage ./vv { });
}
