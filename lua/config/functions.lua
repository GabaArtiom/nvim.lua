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

    -- Локальная навигация внутри плавающего терминала.
    -- Глобальные <C-j>/<C-k> в terminal-mode делают `wincmd j/k` — это просто
    -- перекидывает фокус в редактор за флоатом. Здесь вместо этого пробрасываем
    -- стрелки прямо в терминал, оставаясь в режиме вставки: так навигация по
    -- истории команд / пунктам меню (fzf, lazygit, автодополнение) работает.
    local opts = { buffer = terminal_state.buf, silent = true }
    vim.keymap.set("t", "<C-j>", "<Down>", opts)
    vim.keymap.set("t", "<C-k>", "<Up>", opts)
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


-- Block comment toggle for CSS/SCSS
-- Wraps the visual selection in a single /* */ block instead of commenting
-- every line separately. If the selection is anywhere inside an existing
-- block (cursor need not touch the /* or */ lines), the wrapper is removed.
function M.toggle_block_comment()
  local s = vim.fn.line("v")
  local e = vim.fn.line(".")
  if s > e then
    s, e = e, s
  end

  -- Leave visual mode so the buffer edit below is not fighting the selection
  vim.cmd("normal! \27")

  local total = vim.api.nvim_buf_line_count(0)
  local function trimmed(lnum)
    return vim.trim(vim.fn.getline(lnum))
  end

  -- Find an enclosing block: scan up from the selection start and down from
  -- the selection end. We are inside a block only if the nearest delimiter
  -- above is `/*` and the nearest one below is `*/`.
  local open_line
  for l = s, 1, -1 do
    local t = trimmed(l)
    if t == "/*" then
      open_line = l
      break
    elseif t == "*/" and l < s then
      break
    end
  end

  local close_line
  for l = e, total do
    local t = trimmed(l)
    if t == "*/" then
      close_line = l
      break
    elseif t == "/*" and l > e then
      break
    end
  end

  if open_line and close_line then
    -- Unwrap: drop the delimiter lines (bottom first to keep indices valid)
    vim.api.nvim_buf_set_lines(0, close_line - 1, close_line, false, {})
    vim.api.nvim_buf_set_lines(0, open_line - 1, open_line, false, {})
    return
  end

  -- Wrap: indent the delimiters to the shallowest non-blank line
  local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
  if #lines == 0 then
    return
  end

  local indent
  for _, line in ipairs(lines) do
    if line:match("%S") then
      local width = #line:match("^%s*")
      if not indent or width < indent then
        indent = width
      end
    end
  end
  indent = string.rep(" ", indent or 0)
  table.insert(lines, 1, indent .. "/*")
  table.insert(lines, indent .. "*/")

  vim.api.nvim_buf_set_lines(0, s - 1, e, false, lines)
end

-- Setup function to register keymaps
function M.setup()
  local map = vim.keymap.set

  -- BEM class helper
  map("n", "<leader>vs", M.copy_bem_class, { desc = "Скопировать BEM-класс в регистр i" })
end

return M
