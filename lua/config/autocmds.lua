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

-- Auto-save on focus lost
vim.api.nvim_create_autocmd("FocusLost", {
  pattern = "*",
  callback = function()
    vim.cmd("silent! wa")
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

-- Не давать фолдам раскрываться при сохранении.
-- UFO на BufWritePost форсированно пересобирает фолды и воссоздаёт их из своего
-- состояния (extmark'и). Фолды, закрытые нативными zc/za, он не отслеживает и
-- теряет. Поэтому запоминаем закрытые фолды до записи и закрываем обратно после
-- того, как UFO отработает (debounce 300мс + асинхронный провайдер).
local fold_group = vim.api.nvim_create_augroup("PreserveFoldsOnWrite", { clear = true })
local pending_folds = {}

local function capture_closed_folds(bufnr)
  local folds = {}
  local win = vim.fn.bufwinid(bufnr)
  if win == -1 then
    return folds
  end
  vim.api.nvim_win_call(win, function()
    local lnum = 1
    local last = vim.api.nvim_buf_line_count(bufnr)
    while lnum <= last do
      local start = vim.fn.foldclosed(lnum)
      if start ~= -1 then
        local stop = vim.fn.foldclosedend(lnum)
        table.insert(folds, start)
        lnum = stop + 1
      else
        lnum = lnum + 1
      end
    end
  end)
  return folds
end

local function restore_closed_folds(bufnr, folds)
  local win = vim.fn.bufwinid(bufnr)
  if win == -1 then
    return
  end
  vim.api.nvim_win_call(win, function()
    local view = vim.fn.winsaveview()
    for _, lnum in ipairs(folds) do
      if lnum <= vim.api.nvim_buf_line_count(bufnr) and vim.fn.foldlevel(lnum) > 0 and vim.fn.foldclosed(lnum) == -1 then
        pcall(vim.api.nvim_win_set_cursor, win, { lnum, 0 })
        pcall(vim.cmd, "silent! normal! zc")
      end
    end
    vim.fn.winrestview(view)
  end)
end

vim.api.nvim_create_autocmd("BufWritePre", {
  group = fold_group,
  pattern = "*",
  callback = function(ev)
    pending_folds[ev.buf] = capture_closed_folds(ev.buf)
  end,
})

vim.api.nvim_create_autocmd("BufWritePost", {
  group = fold_group,
  pattern = "*",
  callback = function(ev)
    local folds = pending_folds[ev.buf]
    pending_folds[ev.buf] = nil
    if not folds or #folds == 0 then
      return
    end
    vim.defer_fn(function()
      if vim.api.nvim_buf_is_valid(ev.buf) then
        restore_closed_folds(ev.buf, folds)
      end
    end, 400)
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
    map("n", "<leader>pf", function()
      local file = vim.fn.expand("%:p")
      vim.cmd("!" .. vim.fn.expand("~/.local/bin/php-cs-fixer") .. " fix --config=" .. vim.fn.expand("~/.config/nvim/.php-cs-fixer.php") .. " " .. file)
    end, { desc = "Format with php-cs-fixer", buffer = true })
  end,
})

-- Vue specific shortcuts
vim.api.nvim_create_autocmd("FileType", {
  pattern = "vue",
  callback = function()
    map("n", "<leader>vc", "<cmd>VueCompile<cr>", { desc = "Compile Vue component", buffer = true })

    -- Автоматически показываем completion при вводе в template
    vim.api.nvim_create_autocmd("TextChangedI", {
      buffer = 0,
      callback = function()
        local line = vim.api.nvim_get_current_line()
        local col = vim.api.nvim_win_get_cursor(0)[2]
        local before = line:sub(1, col)

        -- Если вводим тег (после < и есть буквы)
        if before:match("<%a+$") then
          vim.schedule(function()
            require('blink.cmp').show()
          end)
        end
      end,
    })
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
    map("x", "gc", function()
      require("config.functions").toggle_block_comment()
    end, { desc = "Block comment selection", buffer = true })
  end,
})

-- Guard against an upstream bug in vim.lsp.inlay_hint where stale hint positions
-- can exceed the current line's byte length, crashing nvim_buf_set_extmark and
-- spamming "Invalid 'col': out of range" errors via the decoration provider.
-- Wrap nvim_buf_set_extmark in pcall just for the inlay-hint namespace.
do
  local orig = vim.api.nvim_buf_set_extmark
  local ns_cache
  vim.api.nvim_buf_set_extmark = function(bufnr, ns, lnum, col, opts)
    if not ns_cache then
      local all = vim.api.nvim_get_namespaces()
      ns_cache = all["nvim.lsp.inlayhint"]
    end
    if ns == ns_cache then
      local ok, res = pcall(orig, bufnr, ns, lnum, col, opts)
      if ok then return res end
      return nil
    end
    return orig(bufnr, ns, lnum, col, opts)
  end
end

-- Invalidate LuaSnip docstring cache so completion previews reflect the current
-- value of register `i` (BEM base class) instead of a stale snapshot.
vim.api.nvim_create_autocmd("InsertEnter", {
  callback = function()
    local ok, ls = pcall(require, "luasnip")
    if not ok then return end
    local ft_snippets = ls.get_snippets(vim.bo.filetype) or {}
    for _, snip in pairs(ft_snippets) do
      if type(snip) == "table" then
        snip._docstring = nil
      end
    end
  end,
})

-- Disable Neovim's built-in LSP document-color background highlight (enabled by
-- default since 0.12). It draws a background box over color values, duplicating
-- NvChad colorify's swatch, which is the only indicator we want to keep.
if vim.lsp.document_color then
  vim.lsp.document_color.enable(false)
end

-- SCSS/SASS shortcuts
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "scss", "sass" },
  callback = function()
    vim.opt_local.commentstring = "/* %s */"
    map("i", "<C-n>", "<CR>&<Space>", { desc = "SCSS nesting", buffer = true })
    map("x", "gc", function()
      require("config.functions").toggle_block_comment()
    end, { desc = "Block comment selection", buffer = true })
  end,
})

