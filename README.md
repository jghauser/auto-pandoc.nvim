# auto-pandoc.nvim

This plugin allows you to easily convert your markdown files using pandoc. It uses a custom key in the yaml block at the beginning of the markdown file to set pandoc settings. Converting your file then just requires running the supplied command (see below under configuration). This allows for quickly updating the file without having to supply file formats and other settings.

## Installation

This plugin requires neovim 0.5 and depends on the plugin [plenary.nvim](https://github.com/nvim-lua/plenary.nvim).

Packer:

```lua
use {
  'jghauser/auto-pandoc.nvim',
  requires = 'nvim-lua/plenary.nvim',
}
```

Lazy.nvim
```lua
{
    "jghauser/auto-pandoc.nvim",
    dependencies = { "nvim-lua/plenary.nvim" },
    ft = "markdown",
}
```

## Configuration

The plugin provides the `run_pandoc()` function that will execute pandoc. For convencience sake, it's useful to add a keymap for it. The following snippet will add a keymap for markdown files so that `go` executes pandoc (in normal mode). Adapt to your preferences.

```lua
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
```

## Use

Use the `pandoc_` key in the yaml block to set options supplied to the pandoc command. The only deviation from the conventions of the pandoc cli program is the `output` field. You can either set it to your desired filename (in which case it works exactly like pandoc's `--output`) or you can set it to the filename extension prepended by a '.' (e.g. '.pdf'). In that case, auto-pandoc will pass an `--output` value to pandoc that is the current filename with the extension swapped out (e.g. 'my_file.md' will generate a 'my_file.pdf').

Boolean options must be set to true/false (e.g. `option: true` instead of just `option`).

```yaml
---
pandoc_:
  - output: .pdf
  - defaults: academic # this is just an example option, adapt to your preference
---
```

## Todo/limitations

- Plugin doesn't currently deal well with spaces in file and directory names.
