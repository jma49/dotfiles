-- Runs last in the setup process; plain Lua that fits nowhere else goes here

-- Tell kitty when nvim is running (the in_editor user var) so its nvim-only
-- shortcuts (cmd+s, cmd+p, ...) fire here and never type into a shell.
-- See https://sw.kovidgoyal.net/kitty/mapping/#conditional-mappings
local function set_kitty_var(value)
  local seq = "\x1b]1337;SetUserVar=in_editor" .. value .. "\007"
  if vim.api.nvim_ui_send then
    vim.api.nvim_ui_send(seq)
  else
    io.stdout:write(seq)
  end
end

vim.api.nvim_create_autocmd({ "VimEnter", "VimResume", "UIEnter" }, {
  group = vim.api.nvim_create_augroup("KittySetVarVimEnter", { clear = true }),
  callback = function() set_kitty_var "=MQ==" end,
})

vim.api.nvim_create_autocmd({ "VimLeave", "VimSuspend" }, {
  group = vim.api.nvim_create_augroup("KittyUnsetVarVimLeave", { clear = true }),
  callback = function() set_kitty_var "" end,
})
