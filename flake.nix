{
  description = "Custom U-Boot build using nixpkgs' buildUBoot, with fetchgit sourced source";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs }:
    let
      targetSystem = "aarch64-linux";
      pkgs = nixpkgs.legacyPackages.${targetSystem};

      defaultVersion = "2026.07-rc1";
      defaultSrc = pkgs.fetchgit {
        url = "https://gitlab.denx.de/u-boot/u-boot.git";
        rev = "v${defaultVersion}";
        hash = "sha256-1k6id9qj5rnn6sk492qa179g48sqyf3ash37x3x8krycs3zzhvv4";
      };
      myDefconfig = ./my-board_defconfig;
      myPatches = [ ];

      customUboot = pkgs.buildUBoot rec {
        defconfig = "mt8188_ciri_defconfig";
        version = defaultVersion;
        src = defaultSrc;
        postPatch = ''
          echo "Replacing defconfig with custom version..."
          cp ${myDefconfig} configs/${defconfig}
          ${pkgs.buildUBoot.postPatch or ""}
        '';
        extraPatches = myPatches;
      };
    in
    {
      packages.${targetSystem}.uboot = customUboot;
      packages.${targetSystem}.default = customUboot;

      devShells.${targetSystem}.default = pkgs.mkShell {
        buildInputs = with pkgs; [
          gcc
          dtc
          openssl
          python3
        ];
        shellHook = ''
          echo "U-Boot source is available in: ${defaultSrc}"
          echo "Build with: nix build .#uboot"
        '';
      };
    };
}
