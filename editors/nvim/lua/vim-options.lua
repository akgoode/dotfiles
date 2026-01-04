vim.opt.expandtab = true
vim.opt.tabstop = 2
vim.opt.softtabstop = 2
vim.opt.shiftwidth = 2
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.cursorline = true
vim.g.mapleader = " "
vim.diagnostic.config({
  virtual_text = true,     -- show inline messages
  signs = true,            -- show signs in the gutter
  underline = true,        -- underline problematic text
  update_in_insert = false, -- don't update diagnostics while typing
  severity_sort = true,    -- sort diagnostics by severity
})
local n_opts = { silent = true, noremap = true }
local t_opts = { silent = true }

local keymap = vim.keymap.set

-- Normal mode
-- Better window navigation
keymap("n", "<leader>wh", "<C-w>h", n_opts)
keymap("n", "<leader>wj", "<C-w>j", n_opts)
keymap("n", "<leader>wk", "<C-w>k", n_opts)
keymap("n", "<leader>wl", "<C-w>l", n_opts)

-- Terminal mode
keymap("t", "<esc>", "<C-\\><C-N>", t_opts)
keymap("t", "<C-Left>", "<C-\\><C-N><C-w>h", t_opts)
keymap("t", "<C-Down>", "<C-\\><C-N><C-w>j", t_opts)
keymap("t", "<C-Up>", "<C-\\><C-N><C-w>k", t_opts)
keymap("t", "<C-Right>", "<C-\\><C-N><C-w>l", t_opts)

keymap("i", "jk", "<ESC>")
keymap("n", "<leader>ws", ":w<CR>")
keymap("n", "<leader>wq", ":wq<CR>")
keymap("n", "J", "5j")
keymap("n", "K", "5k")
keymap("n", "<leader>q", "q<CR>")
keymap("n", "<leader>`", ":split (:sp) | terminal<CR>")
