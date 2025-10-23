-- lua/config/tab-split.lua
-- Функция для создания вертикального сплита с правым буфером из bufferline

local function split_with_left_buffer()
  local current_buffer = vim.fn.bufnr("%")

  -- Пытаемся получить порядок буферов из bufferline
  local bufferline_ok, bufferline_state = pcall(require, "bufferline.state")
  local right_buffer = nil

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

    if current_index and current_index < #components then
      -- Берем буфер справа от текущего в bufferline
      right_buffer = components[current_index + 1].id
    elseif current_index and #components > 1 then
      -- Если мы на последнем буфере, берем первый (циклический переход)
      right_buffer = components[1].id
    end
  end

  -- Если bufferline не сработал, используем fallback - альтернативный буфер
  if not right_buffer then
    right_buffer = vim.fn.bufnr("#")
    if right_buffer == -1 or right_buffer == current_buffer or not vim.fn.buflisted(right_buffer) then
      -- Последний fallback - первый доступный буфер
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.fn.buflisted(buf) == 1 and buf ~= current_buffer then
          right_buffer = buf
          break
        end
      end
    end
  end

  if not right_buffer or right_buffer == current_buffer then
    vim.notify("Не найден подходящий буфер для сплита", vim.log.levels.WARN)
    return
  end

  -- Создаем вертикальный сплит справа
  vim.cmd("rightbelow vsplit")

  -- Сейчас мы в правом окне с текущим буфером, открываем правый буфер
  vim.cmd("buffer " .. right_buffer)

  -- Возвращаемся в левое окно с текущим буфером
  vim.cmd("wincmd h")
end

-- Настройка keymap
vim.keymap.set("n", "<leader>vv", split_with_left_buffer, {
  desc = "Split with right buffer from bufferline",
  silent = true,
})
