{
  name,
  self,
}: final: prev: let
  auto-pandoc-nvim-luaPackage-override = luaself: luaprev: {
    auto-pandoc-nvim = luaself.callPackage ({
      buildLuarocksPackage,
      lua,
      luaOlder,
      plenary-nvim,
    }:
      buildLuarocksPackage {
        pname = name;
        version = "scm-1";
        knownRockspec = "${self}/${name}-scm-1.rockspec";
        disabled = luaOlder "5.1";
        propagatedBuildInputs = [
          plenary-nvim
        ];
        src = self;
      }) {};
  };

  lua5_1 = prev.lua5_1.override {
    packageOverrides = auto-pandoc-nvim-luaPackage-override;
  };
  lua51Packages = prev.lua51Packages // final.lua5_1.pkgs;
  luajit = prev.luajit.override {
    packageOverrides = auto-pandoc-nvim-luaPackage-override;
  };
  luajitPackages = prev.luajitPackages // final.luajit.pkgs;
in {
  inherit
    lua5_1
    lua51Packages
    luajit
    luajitPackages
    ;

  vimPlugins =
    prev.vimPlugins
    // {
      auto-pandoc-nvim = final.neovimUtils.buildNeovimPlugin {
        pname = name;
        src = self;
        version = "dev";
      };
    };
}
