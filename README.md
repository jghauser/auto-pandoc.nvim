# auto-pandoc.nvim

**WIP**

This plugin allows you to easily convert your markdown files using pandoc. It uses a custom key in the yaml block at the beginning of the markdown file to set pandoc settings. Converting your file then just requires running the supplied command (see below under configuration). This allows for quickly updating the file without having to supply file formats and other settings.

## Installation

Packer:

```lua
use {
  'jghauser/auto-pandoc.nvim',
  config = function()
    require('auto-pandoc')
  end
}
```

## Configuration

I added the following keymap to my `ftplugin/markdown.vim`. It will save the file and execute pandoc on `go`. Adapt to your preferences.

```viml
nnoremap <buffer><silent> go :w<bar>lua require('auto-pandoc').run_pandoc()<cr>
```

## Use

Use a `pandoc_` key in the yaml block to set pandoc options. The `to` field defines the output format, other fields follow the naming convention of the pandoc cli program.

```yaml
---
pandoc_:
  - to: pdf
  - defaults: academic
---
```

## TODO

- Use plenary for running jobs. Give feedback when pandoc conversion fails.
