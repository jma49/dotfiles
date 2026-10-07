-- This file simply bootstraps the installation of Lazy.nvim and then calls other files for execution
-- This file doesn't necessarily need to be touched, BE CAUTIOUS editing this file and proceed at your own risk.

-- If the working directory has been deleted out from under us (e.g. launching Nvim from
-- a shell whose cwd was `rm -rf`'d), `uv.cwd()` returns nil. Neovim then cannot expand
-- relative paths, which breaks `vim.fs.abspath` -- taking filetype detection and
-- AstroNvim's `AstroFile` autocmd down with it (no syntax highlighting, error on every
-- file open). Fall back to $HOME so the rest of startup behaves normally.
-- Must run before any file argument is loaded, hence the position at the top of init.lua.
if not vim.uv.cwd() then
  vim.notify("cwd is no longer accessible, falling back to $HOME", vim.log.levels.WARN)
  pcall(vim.cmd.cd, vim.env.HOME)
end

local lazypath = vim.env.LAZY or vim.fn.stdpath "data" .. "/lazy/lazy.nvim"
if not (vim.env.LAZY or (vim.uv or vim.loop).fs_stat(lazypath)) then
  -- stylua: ignore
  vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git", "--branch=stable", lazypath })
end
vim.opt.rtp:prepend(lazypath)

-- validate that lazy is available
if not pcall(require, "lazy") then
  -- stylua: ignore
  vim.api.nvim_echo({ { ("Unable to load lazy from: %s\n"):format(lazypath), "ErrorMsg" }, { "Press any key to exit...", "MoreMsg" } }, true, {})
  vim.fn.getchar()
  vim.cmd.quit()
end

vim.api.nvim_set_keymap("i", "jk", "<ESC>", { noremap = true, silent = true })

require "lazy_setup"
require "polish"
