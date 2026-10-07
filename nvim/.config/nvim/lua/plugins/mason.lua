-- Customize Mason
--
-- NOTE: As of AstroNvim v5, mason-tool-installer owns all package installation.
-- When it is available AstroNvim nils out `mason-lspconfig`'s `ensure_installed`,
-- so everything below uses **Mason package names** (the ones shown in `:Mason`),
-- not lspconfig server names (e.g. `lua-language-server`, not `lua_ls`).

---@type LazySpec
return {
  {
    "WhoIsSethDaniel/mason-tool-installer.nvim",
    -- overrides `require("mason-tool-installer").setup(...)`
    opts = {
      ensure_installed = {
        -- language servers
        "lua-language-server",
        "pyright",

        -- formatters / linters
        "prettier",
        "stylua",

        -- debuggers
        "debugpy",

        -- required by nvim-treesitter's `main` branch to compile parsers
        "tree-sitter-cli",
      },
    },
  },
}
