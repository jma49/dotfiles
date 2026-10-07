return {
  {
    "folke/noice.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
    },
    config = function()
      require("noice").setup {
        messages = { enabled = true },
        cmdline = { view = "cmdline_popup" },
        -- snacks.notifier (AstroNvim's default) owns vim.notify
        notify = { enabled = false },
        -- AstroLSP wraps `vim.lsp.buf.hover` / `signature_help` to apply its own
        -- defaults (`silent`, `focusable`), which noice reports as "overwritten by
        -- another plugin". Let AstroLSP own them so the warnings stop.
        lsp = {
          hover = { enabled = false },
          signature = { enabled = false },
        },
      }
    end,
  },
}
