return {
  {
    "folke/noice.nvim",
    dependencies = {
      "MunifTanjim/nui.nvim",
      "rcarriga/nvim-notify",
    },
    config = function()
      require("noice").setup {
        -- 配置选项
        messages = { enabled = true },
        cmdline = { view = "cmdline_popup" },
        notify = { enabled = true },
      }
    end,
  },
}
