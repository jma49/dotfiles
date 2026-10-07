-- heirline is AstroNvim's native statusline/tabline/winbar engine.
--
-- This config previously never rendered, because `sttusline` overwrote `vim.o.statusline`
-- on BufEnter. sttusline has since been archived by its author, so it was removed and
-- this statusline is live again.
--
-- `winbar = false` is load-bearing: heirline ships a breadcrumbs winbar, and disabling it
-- is what leaves the winbar free for dropbar.nvim (see `plugins/dropbar.lua`).

---@type LazySpec
return {
  "rebelot/heirline.nvim",
  opts = function(_, opts)
    local status = require "astroui.status"

    local WorkDir = {
      init = function(self)
        self.icon = "  "
        local cwd = vim.fn.getcwd(0)
        self.cwd = vim.fn.fnamemodify(cwd, ":~")
      end,
      hl = { fg = "white", bold = true },

      flexible = 1,

      {
        -- evaluates to the full-length path
        provider = function(self)
          local trail = self.cwd:sub(-1) == "/" and "" or "/"
          return self.icon .. self.cwd .. trail .. " "
        end,
      },
      {
        -- evaluates to the shortened path
        provider = function(self)
          local cwd = vim.fn.pathshorten(self.cwd)
          local trail = self.cwd:sub(-1) == "/" and "" or "/"
          return self.icon .. cwd .. trail .. " "
        end,
      },
      {
        -- evaluates to "", hiding the component
        provider = "",
      },
    }

    opts.statusline = {
      hl = { fg = "fg", bg = "bg" },
      -- Dark text on the bright mode background; astroui's mode highlight sets only the
      -- background, so the text otherwise inherits the light statusline fg
      status.component.mode { mode_text = { padding = { left = 1, right = 1 } }, hl = { fg = "mode_fg", bold = true } },
      status.component.git_branch(),
      status.component.file_info(),
      status.component.git_diff(),
      status.component.diagnostics(),
      status.component.builder(WorkDir),
      status.component.fill(),
      status.component.cmd_info(),
      status.component.fill(),
      status.component.lsp(),
      status.component.virtual_env(),
      status.component.nav(),
    }

    opts.winbar = false
  end,
}
