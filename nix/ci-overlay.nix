# Add flake.nix test inputs as arguments here
{
  self,
  name,
}: final: prev: let
  mkNvimMinimal = nvim:
    with final; let
      neovimConfig = neovimUtils.makeNeovimConfig {
        withPython3 = false;
        viAlias = true;
        vimAlias = true;
        extraLuaPackages = luaPkgs: [
          luaPkgs.auto-pandoc-nvim
        ];
        plugins = with vimPlugins; [
          nvim-cmp
          (nvim-treesitter.withPlugins (ps:
            with ps; [
              tree-sitter-yaml
              tree-sitter-markdown
              tree-sitter-markdown-inline
            ]))
        ];
      };
      runtimeDeps = [
        pandoc
      ];
    in
      final.wrapNeovimUnstable nvim (neovimConfig
        // {
          wrapperArgs =
            lib.escapeShellArgs neovimConfig.wrapperArgs
            + " "
            + ''--set NVIM_APPNAME "nvim-${name}"''
            + " "
            + ''--prefix PATH : "${lib.makeBinPath runtimeDeps}"'';
          wrapRc = true;
          neovimRcContent =
            # lua
            ''
              lua << EOF
              local o = vim.o
              local cmd = vim.cmd
              local fn = vim.fn
              local keymap = vim.keymap

              -- disable swap
              o.swapfile = false

              -- add current directory to runtimepath to have the plugin
              -- be loaded from the current directory
              vim.opt.runtimepath:prepend(vim.fn.getcwd())

              -- remap leader
              vim.g.mapleader = " "

              ---Sets up auto-pandoc.nvim
              ---@param opts table? Custom configuration options
              ---@param rm_db boolean? Remove db on startup (defaults to `true`)
              vim.api.nvim_create_autocmd("BufEnter", {
                pattern = "*.md",
                callback = function()
                  keymap.set("n", "go", function()
                    require("auto-pandoc").run_pandoc()
                  end, { silent = true, buffer = 0 })
                end,
                group = vim.api.nvim_create_augroup("setAutoPandocKeymap", {}),
                desc = "Set keymap for auto-pandoc",
              })
              EOF
            '';
        });
in {
  neovim-with-plugin = mkNvimMinimal final.neovim-unwrapped;
}
