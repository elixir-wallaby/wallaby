{
  description = "Wallaby";

  inputs = {
    beam-flakes = {
      url = "github:mhanberg/nix-beam-flakes";
      inputs.flake-parts.follows = "flake-parts";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    flake-parts.url = "github:hercules-ci/flake-parts";
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
  };

  outputs = inputs @ {
    beam-flakes,
    flake-parts,
    ...
  }:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [beam-flakes.flakeModule];

      systems = ["aarch64-darwin" "x86_64-darwin" "x86_64-linux"];

      perSystem = {pkgs, ...}: let
        selenium-server = pkgs.callPackage ./nix/selenium-server.nix {};
      in {
        packages.selenium-server = selenium-server;
        beamWorkspace = {
          enable = true;
          devShell = {
            packages = with pkgs; [
              selenium-server
              selenium-server-standalone
              chromedriver
              geckodriver
              firefox
            ];
            languageServers.elixir = false;
            languageServers.erlang = false;
          };

          versions = {fromToolVersions = ./.tool-versions;};
        };
      };
    };
}
