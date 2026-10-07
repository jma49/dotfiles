-- snacks.nvim replaces alpha-nvim (dashboard), dressing.nvim, nvim-notify and
-- indent-blankline, all of which stopped shipping with AstroNvim in v5.
-- The dashboard header below is the one that used to live in `plugins/alpha.lua`.

---@type LazySpec
return {
  "folke/snacks.nvim",
  opts = {
    -- Snacks owns vim.ui.input (rename prompts, etc.)
    input = { enabled = true },
    -- herdr passes the kitty graphics protocol through to kitty, but snacks only
    -- recognizes terminals by name (TERM_PROGRAM=herdr isn't one), so force it there
    image = { force = vim.env.TERM_PROGRAM == "herdr" },
    dashboard = {
      preset = {
        header = table.concat({
          "      ██╗██╗███╗   ██╗ ██████╗██╗  ██╗███████╗███╗   ██╗ ██████╗  ",
          "      ██║██║████╗  ██║██╔════╝██║  ██║██╔════╝████╗  ██║██╔════╝  ",
          "      ██║██║██╔██╗ ██║██║     ███████║█████╗  ██╔██╗ ██║██║  ███╗ ",
          " ██   ██║██║██║╚██╗██║██║     ██╔══██║██╔══╝  ██║╚██╗██║██║   ██║ ",
          " ╚█████╔╝██║██║ ╚████║╚██████╗██║  ██║███████╗██║ ╚████║╚██████╔╝ ",
          "  ╚════╝ ╚═╝╚═╝  ╚═══╝ ╚═════╝╚═╝  ╚═╝╚══════╝╚═╝  ╚═══╝ ╚═════╝  ",
        }, "\n"),
      },
    },
  },
}
