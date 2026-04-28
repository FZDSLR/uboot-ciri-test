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
        hash = "sha256-ZG/4/9DM54n66GdArYbzWCPy0gkKi0SmNtbmInFq0cw=";
      };
      myDefconfig = ./mt8188_ciri_defconfig;
      myDefconfigName = "mt8188_ciri_defconfig";
      myPatches = [ ];

      customUboot =
        (pkgs.buildUBoot {
          defconfig = "mt8188_ciri_defconfig";
          version = defaultVersion;
          src = defaultSrc;
          filesToInstall = [
            "u-boot"
            "u-boot.dtb"
            "u-boot.bin"
            "u-boot-dtb.bin"
            "u-boot-mtk.bin"
            ".config"
          ];

          extraPatches = myPatches;
        }).overrideAttrs
          (
            finalAttrs: previousAttrs: {
              postPatch = previousAttrs.postPatch or "" + ''
                echo "Replacing defconfig with custom version..."
                cp ${myDefconfig} configs/${myDefconfigName}
              '';
            }
          );
    in
    {
      packages = {
        ${targetSystem} = {
          uboot = customUboot;
          default = customUboot;
        };
      };

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
