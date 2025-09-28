-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")


-- Set specific tab settings for web development
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascript", "typescript", "javascriptreact", "typescriptreact", "vue", "css", "scss", "sass", "html" },
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})

-- PHP specific settings
vim.api.nvim_create_autocmd("FileType", {
  pattern = "php",
  callback = function()
    vim.opt_local.tabstop = 2
    vim.opt_local.shiftwidth = 2
    vim.opt_local.expandtab = true
  end,
})

-- Enable wrap for markdown files
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "md" },
  callback = function()
    vim.opt_local.wrap = true
    vim.opt_local.linebreak = true
  end,
})

-- Auto-reload browser when saving CSS/HTML files (if bracey is running)
vim.api.nvim_create_autocmd("BufWritePost", {
  pattern = { "*.html", "*.css", "*.js" },
  callback = function()
    vim.cmd("silent! BraceyReload")
  end,
})

-- Highlight on yank
vim.api.nvim_create_autocmd("TextYankPost", {
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 200 })
  end,
})

-- Remove trailing whitespace on save
vim.api.nvim_create_autocmd("BufWritePre", {
  pattern = "*",
  callback = function()
    local save_cursor = vim.fn.getpos(".")
    vim.cmd([[%s/\s\+$//e]])
    vim.fn.setpos(".", save_cursor)
  end,
})

-- File-type specific keymaps
local map = vim.keymap.set

-- PHP specific shortcuts
vim.api.nvim_create_autocmd("FileType", {
  pattern = "php",
  callback = function()
    map("n", "<leader>pa", "<cmd>!php -l %<cr>", { desc = "Check PHP syntax", buffer = true })
    map("n", "<leader>pr", "<cmd>!php %<cr>", { desc = "Run PHP file", buffer = true })
  end,
})

-- Vue specific shortcuts
vim.api.nvim_create_autocmd("FileType", {
  pattern = "vue",
  callback = function()
    map("n", "<leader>vc", "<cmd>VueCompile<cr>", { desc = "Compile Vue component", buffer = true })
  end,
})

-- JavaScript/TypeScript shortcuts
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "javascript", "typescript", "javascriptreact", "typescriptreact" },
  callback = function()
    map("n", "<leader>ji", "<cmd>TypescriptOrganizeImports<cr>", { desc = "Organize imports", buffer = true })
    map("n", "<leader>jr", "<cmd>TypescriptRenameFile<cr>", { desc = "Rename file", buffer = true })
  end,
})

-- HTML shortcuts
vim.api.nvim_create_autocmd("FileType", {
  pattern = "html",
  callback = function()
    map("n", "<leader>h5", "i<!DOCTYPE html><CR><html lang=\"en\"><CR><head><CR><meta charset=\"UTF-8\"><CR><meta name=\"viewport\" content=\"width=device-width, initial-scale=1.0\"><CR><title>Document</title><CR></head><CR><body><CR><CR></body><CR></html><Esc>", { desc = "Insert HTML5 skeleton", buffer = true })
  end,
})

-- CSS shortcuts
vim.api.nvim_create_autocmd("FileType", {
  pattern = "css",
  callback = function()
    vim.opt_local.commentstring = "/* %s */"
    map("i", "dfc", "display: flex;<CR>justify-content: center;<CR>align-items: center;", { desc = "Flex center", buffer = true })
    map("i", "dgc", "display: grid;<CR>place-items: center;", { desc = "Grid center", buffer = true })
  end,
})

-- SCSS/SASS shortcuts
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "scss", "sass" },
  callback = function()
    vim.opt_local.commentstring = "/* %s */"
    map("i", "<C-n>", "<CR>&<Space>", { desc = "SCSS nesting", buffer = true })
  end,
})

