return {
  "catppuccin/nvim",
  priority = 1000, -- Make sure to load this before all the other start plugins.
  config = function()
    require("catppuccin").setup {
      flavour = "mocha",
      transparent_background = true,
      -- Upright comments (the default is italic)
      styles = { comments = {} },
      term_colors = true,
      -- Auto-detection calls vim.pack.get() on nvim 0.12, which creates an empty
      -- site/pack/core that lazy then warns about; list integrations explicitly
      auto_integrations = false,
      integrations = {
        aerial = true,
        diffview = true,
        mini = {
          enabled = true,
          indentscope_color = "sky",
        },
        noice = true,
        overseer = true,
        nvimtree = false,
        neotree = true,
        which_key = true,
        treesitter = true,
        notify = true,
        gitsigns = true,
        flash = true,
        blink_cmp = true,
        mason = true,
        snacks = true,
        dap = true,
        dap_ui = true,
        dropbar = { enabled = true },
        render_markdown = true,
        window_picker = true,
      },
      highlight_overrides = {
        mocha = function(mocha)
          return {
            -- default is `surface1` (#45475a), too dim over a transparent background
            LineNr = { fg = mocha.overlay1 },
            -- Secondary text drawn in surface/overlay0/overlay1 vanishes on kitty's
            -- glass over a bright wallpaper; overlay2 keeps it secondary but readable.
            -- Structural marks (indent guides, whitespace, end-of-buffer) stay dim.
            NeoTreeDimText = { fg = mocha.overlay2 },
            NeoTreeFileStats = { fg = mocha.overlay2 },
            NeoTreeFileStatsHeader = { fg = mocha.subtext0, bold = true },
            NeoTreeGitIgnored = { fg = mocha.overlay2 },
            NeoTreeExpander = { fg = mocha.overlay2 },
            NeoTreeMessage = { fg = mocha.overlay2 },
            GitSignsCurrentLineBlame = { fg = mocha.overlay2 },
            LspInlayHint = { fg = mocha.overlay2 },
            LspCodeLens = { fg = mocha.overlay2 },
            PmenuExtra = { fg = mocha.overlay2 },
            WhichKeyValue = { fg = mocha.overlay2 },
            MasonMuted = { fg = mocha.overlay2 },
            Conceal = { fg = mocha.overlay2 },
            FoldColumn = { fg = mocha.overlay2 },
            -- Window dividers a step brighter, matching kitty and herdr borders
            WinSeparator = { fg = mocha.overlay0 },
            VertSplit = { fg = mocha.overlay0 },
            NeoTreeWinSeparator = { fg = mocha.overlay0 },
            CursorLineNr = { fg = mocha.yellow, bold = true },
            -- noice's cmdline popup defaults to Normal (no background), which shows
            -- kitty's glass through an otherwise solid float; make it solid mantle
            -- like NormalFloat
            NoiceCmdlinePopup = { bg = mocha.mantle },
            NoiceCmdlinePopupBorder = { fg = mocha.lavender, bg = mocha.mantle },
            NoiceCmdlinePopupTitle = { fg = mocha.lavender, bg = mocha.mantle },
            NoiceCmdlinePopupBorderSearch = { fg = mocha.yellow, bg = mocha.mantle },
          }
        end,
      },
    }
  end,
}
