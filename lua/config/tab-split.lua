-- lua/config/tab-split.lua
-- Функция для создания вертикального сплита с левым буфером из bufferline

local function split_with_left_buffer()
  local current_buffer = vim.fn.bufnr("%")

  -- Пытаемся получить порядок буферов из bufferline
  local bufferline_ok, bufferline_state = pcall(require, "bufferline.state")
  local left_buffer = nil

  if bufferline_ok and bufferline_state then
    local components = bufferline_state.components or {}
    local current_index = nil

    -- Находим текущий буфер в списке bufferline
    for i, component in ipairs(components) do
      if component.id == current_buffer then
        current_index = i
        break
      end
    end

    if current_index and current_index > 1 then
      -- Берем буфер слева от текущего в bufferline
      left_buffer = components[current_index - 1].id
    elseif current_index and #components > 1 then
      -- Если мы на первом буфере, берем последний (циклический переход)
      left_buffer = components[#components].id
    end
  end

  -- Если bufferline не сработал, используем fallback - альтернативный буфер
  if not left_buffer then
    left_buffer = vim.fn.bufnr("#")
    if left_buffer == -1 or left_buffer == current_buffer or not vim.fn.buflisted(left_buffer) then
      -- Последний fallback - первый доступный буфер
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.fn.buflisted(buf) == 1 and buf ~= current_buffer then
          left_buffer = buf
          break
        end
      end
    end
  end

  if not left_buffer or left_buffer == current_buffer then
    vim.notify("Не найден подходящий буфер для сплита", vim.log.levels.WARN)
    return
  end

  -- Создаем вертикальный сплит справа (текущий буфер уйдет вправо)
  vim.cmd("rightbelow vsplit")

  -- Сейчас мы в правом окне с текущим буфером, переходим в левое
  vim.cmd("wincmd h")

  -- В левом окне открываем левый буфер
  vim.cmd("buffer " .. left_buffer)

  -- Возвращаемся в правое окно с текущим буфером
  vim.cmd("wincmd l")
end

-- Настройка keymap
vim.keymap.set("n", "<leader>vv", split_with_left_buffer, {
  desc = "Split with left buffer from bufferline",
  silent = true,
})
