local MODREV, SPECREV = 'scm', '-1'
rockspec_format = '3.0'
package = 'auto-pandoc.nvim'
version = MODREV .. SPECREV

description = {
  summary = 'Use pandoc to convert markdown files according to options from a yaml block',
  detailed = [[
  This plugin allows you to easily convert your markdown files using pandoc.
  It uses a custom key in the yaml block at the beginning of the markdown file
  to set pandoc settings. Converting your file then just requires running the
  supplied command.
  ]],
  labels = { 'neovim', 'plugin', },
  homepage = 'https://github.com/jghauser/auto-pandoc.nvim',
  license = 'GPL3',
}

dependencies = {
  "lua >= 5.1, < 5.4",
  "plenary.nvim",
}

source = {
  url = 'git://github.com/jghauser/auto-pandoc.nvim',
}
