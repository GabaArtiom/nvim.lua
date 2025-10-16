-- Custom functions for Neovim

local M = {}

-- BEM class helper function
function M.copy_bem_class()
  local line = vim.api.nvim_get_current_line()

  -- Ищем class="..." или class='...'
  local class_name = line:match("class%s*=%s*[\"']([^\"']+)[\"']")
  if not class_name then
    vim.notify("Не найден class в строке", vim.log.levels.WARN)
    return
  end

  -- Берем первый класс (до пробела) и добавляем __
  local base_class = vim.split(class_name, "%s+")[1]
  if not base_class or base_class == "" then
    vim.notify("Не удалось определить имя класса", vim.log.levels.ERROR)
    return
  end

  local bem = base_class .. "__"

  -- Копируем в регистр i
  vim.fn.setreg("i", bem)
  vim.notify("Скопировано в регистр i: " .. bem)
end

-- Floating terminal
local terminal_state = {
  buf = nil,
  win = nil,
}

function M.toggle_floating_terminal()
  -- Если окно открыто, закрыть его
  if terminal_state.win and vim.api.nvim_win_is_valid(terminal_state.win) then
    vim.api.nvim_win_close(terminal_state.win, true)
    terminal_state.win = nil
    return
  end

  -- Размеры окна
  local width = math.floor(vim.o.columns * 0.9)
  local height = math.floor(vim.o.lines * 0.9)
  local col = math.floor((vim.o.columns - width) / 2)
  local row = math.floor((vim.o.lines - height) / 2) - 1

  -- Создать буфер если его нет или он не валидный
  if not terminal_state.buf or not vim.api.nvim_buf_is_valid(terminal_state.buf) then
    terminal_state.buf = vim.api.nvim_create_buf(false, true)
  end

  -- Открыть плавающее окно
  terminal_state.win = vim.api.nvim_open_win(terminal_state.buf, true, {
    relative = "editor",
    width = width,
    height = height,
    col = col,
    row = row,
    style = "minimal",
    border = "rounded",
  })

  -- Если терминал еще не запущен, запустить его
  if vim.api.nvim_buf_line_count(terminal_state.buf) == 1 and vim.api.nvim_buf_get_lines(terminal_state.buf, 0, 1, false)[1] == "" then
    vim.fn.termopen(vim.o.shell)
  end

  -- Перейти в режим insert
  vim.cmd("startinsert")
end


-- Setup function to register keymaps
function M.setup()
  local map = vim.keymap.set

  -- BEM class helper
  map("n", "<leader>vs", M.copy_bem_class, { desc = "Скопировать BEM-класс в регистр i" })
end

return M
