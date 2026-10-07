return {
  "petertriho/nvim-scrollbar",
  -- `LazyFile` is a LazyVim pseudo-event; lazy.nvim has it commented out, so this
  -- plugin never actually loaded. `User AstroFile` is AstroNvim's equivalent.
  event = "User AstroFile",
  config = function() require("scrollbar").setup() end,
}
