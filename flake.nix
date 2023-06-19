{
  description = "Phoenix-ci example";

  outputs = { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};

      mkEffectWithDeps = drv: {
        type = "ci-work-unit";
        inherit (drv) drvPath;
        inherit drv;
        findWorkDeps = {
          inherit (pkgs) hello;
        };

        findWork = ''
          // Example how to use dependencies from nix
          await execUtils.execCommandPipeOutput(self.findWorkDeps.hello.path + "/bin/hello", [])

          // Check if derivation not already in binary cache, if it is - execute the build
          const isUncached = await nix.isUncachedDrv(self.drvPath)
          return isUncached
            ? { build: [`''${self.attrPath}.drv`] }
            : {}
        '';
      };

    in
    {

      packages.x86_64-linux = {
        test1 = pkgs.writeText "test1" "test1";
        test2 = pkgs.writeText "test2" "test2";

        # Will not be build since it is already in nixpkgs
        inherit (pkgs) coreutils bash;
      };

      ci.x86_64-linux.default = {
        effectWithDeps = mkEffectWithDeps self.packages.x86_64-linux.test1;
      };
    };
}
