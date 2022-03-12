# auto-pandoc.nvim

This plugin allows you to easily convert your markdown files using pandoc. It uses a custom key in the yaml block at the beginning of the markdown file to set pandoc settings. Converting your file then just requires running the supplied command (see below under configuration). This allows for quickly updating the file without having to supply file formats and other settings.

## Installation

This plugin requires neovim 0.5 and depends on the plugin [plenary.nvim](https://github.com/nvim-lua/plenary.nvim).

Packer:

```lua
use {
  'jghauser/auto-pandoc.nvim',
  requires = 'nvim-lua/plenary.nvim',
  config = function()
    require('auto-pandoc')
  end
}
```

## Configuration

I added the following keymap to my `ftplugin/markdown.lua`. It will save the file and execute pandoc on `go`. Adapt to your preferences.

```lua
vim.api.nvim_buf_set_keymap('0', 'n', 'go', ':silent w<bar>lua require("auto-pandoc").run_pandoc()<cr>', {noremap = true, silent = true})
```

## Use

Use the `pandoc_` key in the yaml block to set options supplied to the pandoc command. The only deviation from the conventions of the pandoc cli program is the `output` field. You can either set it to your desired filename (in which case it works exactly like pandoc's `--output`) or you can set it to the filename extension prepended by a '.' (e.g. '.pdf'). In that case, auto-pandoc will pass an `--output` value to pandoc that is the current filename with the extension swapped out (e.g. 'my_file.md' will generate a 'my_file.pdf').

Boolean options must be set to true/false (e.g. `option: true` instead of just `option`).

```yaml
---
pandoc_:
  - to: pdf
  - defaults: academic
---
```

## Todo/limitations

- Plugin doesn't currently deal well with spaces in file and directory names.
