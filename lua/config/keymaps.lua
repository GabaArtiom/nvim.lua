-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

local map = vim.keymap.set

-- Web Development specific keymaps

-- Live server control
map("n", "<leader>ws", "<cmd>Bracey<cr>", { desc = "Start live server" })
map("n", "<leader>wS", "<cmd>BraceyStop<cr>", { desc = "Stop live server" })
map("n", "<leader>wr", "<cmd>BraceyReload<cr>", { desc = "Reload live server" })

-- Emmet shortcuts
map("i", "<C-z>,", "<Plug>(emmet-expand-abbr)", { desc = "Expand Emmet abbreviation" })
map("n", "<C-z>,", "<Plug>(emmet-expand-abbr)", { desc = "Expand Emmet abbreviation" })

-- Quick formatting
map("n", "<leader>ff", function()
  vim.lsp.buf.format({ async = true })
end, { desc = "Format file" })

-- Alt+L for fast formatting with prettier and spacing
map("n", "<A-l>", function()
  local ft = vim.bo.filetype

  -- Format first - for PHP, use conform with blade-formatter for better HTML handling
  if ft == "php" then
    local conform_ok, conform = pcall(require, "conform")
    if conform_ok then
      conform.format({ async = false, lsp_fallback = true })
    else
      vim.lsp.buf.format({ async = false })
    end
  else
    local conform_ok, conform = pcall(require, "conform")
    if conform_ok then
      conform.format({ async = false, lsp_fallback = true })
    else
      vim.lsp.buf.format({ async = false })
    end
  end

  -- Add spacing between CSS/SCSS elements
  if ft == "scss" or ft == "sass" or ft == "css" then
    local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    local new_lines = {}
    local i = 1

    while i <= #lines do
      local line = lines[i]
      table.insert(new_lines, line)

      -- Check if current line is closing brace and next line starts an element
      if line:match("^%s*}") and i < #lines then
        local next_line = lines[i + 1]
        -- If next line is not empty and not a closing brace and not already has spacing
        if next_line and not next_line:match("^%s*$") and not next_line:match("^%s*}") then
          table.insert(new_lines, "")
        end
      end

      i = i + 1
    end

    vim.api.nvim_buf_set_lines(0, 0, -1, false, new_lines)
  end
end, { desc = "Format with prettier and spacing" })


map("v", "<A-l>", function()
  vim.lsp.buf.format({ async = false })
end, { desc = "Format selection" })

-- CSS/SCSS color picker
map("n", "<leader>cp", "<cmd>ColorizerToggle<cr>", { desc = "Toggle color preview" })

-- Theme picker (using improved volt 2025)
map("n", "<leader>th", function()
  require("nvchad.themes").open()
end, { desc = "Theme picker (Volt UI)" })

-- File-type specific shortcuts will be set via autocmds

-- Quick save without formatting and preserve folds
map("n", "<C-s>", function()
  -- Сохраняем фолды и курсор
  local view = vim.fn.winsaveview()

  -- Сохраняем файл
  vim.cmd("silent! write")

  -- После небольшой задержки — восстанавливаем фолды
  vim.defer_fn(function()
    pcall(vim.fn.winrestview, view)
  end, 50)
end, { desc = "Save file without unfolding" })

-- Better indenting
map("v", "<", "<gv", { desc = "Indent left and reselect" })
map("v", ">", ">gv", { desc = "Indent right and reselect" })


-- Better paste
map("v", "p", '"_dP', { desc = "Paste without yanking" })

-- Clear search with <esc>
map("n", "<esc>", "<cmd>noh<cr><esc>", { desc = "Escape and clear hlsearch" })

-- Terminal
map("t", "<C-h>", "<cmd>wincmd h<cr>", { desc = "Go to left window" })
map("t", "<C-j>", "<cmd>wincmd j<cr>", { desc = "Go to lower window" })
map("t", "<C-k>", "<cmd>wincmd k<cr>", { desc = "Go to upper window" })
map("t", "<C-l>", "<cmd>wincmd l<cr>", { desc = "Go to right window" })
map("t", "<C-/>", "<cmd>close<cr>", { desc = "Hide terminal" })
map("t", "<c-_>", "<cmd>close<cr>", { desc = "Hide terminal" })

-- Floating terminal toggle
map("n", "<C-;>", function()
  require("config.functions").toggle_floating_terminal()
end, { desc = "Toggle floating terminal" })
map("t", "<C-;>", function()
  require("config.functions").toggle_floating_terminal()
end, { desc = "Toggle floating terminal" })

-- Сохранить и выйти
map("n", "<leader>qq", "<cmd>wqa<cr>", { desc = "Сохранить и выйти" })
map("n", "<leader>QQ", "<cmd>qa!<cr>", { desc = "Выход без сохранений" })

-- Изменение размера окна с шагом
map("n", "<C-Right>", "<cmd>vertical resize +10<CR>", { desc = "Expand window right" })
map("n", "<C-Left>", "<cmd>vertical resize -10<CR>", { desc = "Shrink window left" })
map("n", "<C-Up>", "<cmd>resize -5<CR>", { desc = "Shrink window height" })
map("n", "<C-Down>", "<cmd>resize +5<CR>", { desc = "Expand window height" })

-- insert mode: Ctrl-j -> выход из insert и вставка новой строки
vim.keymap.set("i", "<C-j>", "<Esc>o", { noremap = true, silent = true, desc = "Insert new line below" })
vim.keymap.set("i", "jj", "<Esc>", { noremap = true, silent = true, desc = "Exit insert mode" })

-- Сохранить все файлы
map("n", "<leader>a", "<cmd>wa<cr>", { desc = "Save all files" })

-- Переключение между буферами
vim.keymap.set("n", "<S-h>", "<cmd>BufferLineCyclePrev<CR>", { desc = "Prev buffer" })
vim.keymap.set("n", "<S-l>", "<cmd>BufferLineCycleNext<CR>", { desc = "Next buffer" })

-- Debug formatters
map("n", "<leader>fd", function()
  local conform = require("conform")
  local filetype = vim.bo.filetype
  local formatters = conform.list_formatters_for_buffer()

  print("Filetype: " .. filetype)
  print("Available formatters:")
  for _, formatter in ipairs(formatters) do
    print("  - " .. formatter.name .. " (" .. (formatter.available and "available" or "not available") .. ")")
  end

  if #formatters == 0 then
    print("No formatters configured for filetype: " .. filetype)
  end
end, { desc = "Debug formatters" })

-- Alternative PHP formatting with php-cs-fixer (for pure PHP files)
map("n", "<leader>fp", function()
  if vim.bo.filetype == "php" then
    local conform = require("conform")
    conform.format({
      formatters = { "php-cs-fixer" },
      async = false,
    })
  else
    print("php-cs-fixer is only for PHP files")
  end
end, { desc = "Format PHP with php-cs-fixer" })

-- Перенос буферов
vim.keymap.set("n", "<C-S-h>", "<cmd>BufferLineMovePrev<CR>", { desc = "Move buffer left" })
vim.keymap.set("n", "<C-S-l>", "<cmd>BufferLineMoveNext<CR>", { desc = "Move buffer right" })
