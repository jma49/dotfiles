-- Customize Treesitter
-- --------------------
-- As of AstroNvim v5, nvim-treesitter tracks its `main` branch and is only a parser
-- download utility -- all the actual highlight/indent/textobject config lives in AstroCore.
-- Parsers installed under v4 (the `master` branch) do not carry over; run `:TSUpdate`
-- after the upgrade to rebuild them.

---@type LazySpec
return {
  "AstroNvim/astrocore",
  ---@type AstroCoreOpts
  opts = {
    treesitter = {
      highlight = true,
      indent = true,
      auto_install = true, -- install parsers on demand when opening a new filetype
      ensure_installed = {
        -- regex is for noice cmdline highlighting; css, html, latex, scss, svelte, tsx,
        -- typst and vue let snacks and render-markdown render images and math in docs
        "bash",
        "c",
        "cpp",
        "css",
        "go",
        "html",
        "java",
        "javascript",
        "json",
        "latex",
        "lua",
        "luadoc",
        "markdown",
        "markdown_inline",
        "python",
        "query",
        "regex",
        "scss",
        "svelte",
        "toml",
        "tsx",
        "typescript",
        "typst",
        "vim",
        "vimdoc",
        "vue",
        "yaml",
      },
    },
  },
}
