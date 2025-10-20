-- Функция для конвертации px в rem
local function px_to_rem()
  -- Получаем текущий буфер
  local buf = vim.api.nvim_get_current_buf()

  -- Получаем все строки из буфера
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)

  -- Счетчик замен
  local replacements = 0

  -- Проходим по каждой строке
  for i, line in ipairs(lines) do
    -- Заменяем все вхождения px на rem, игнорируя border, letter-spacing и media queries
    -- Паттерн ищет число (включая десятичные) + "px", но не в этих свойствах
    local new_line = line:gsub("(%d+%.?%d*)px", function(num)
      -- Проверяем, не находится ли px в border свойстве
      local border_pattern = "border[^:]*:%s*[^;]*" .. num .. "px"
      if line:match(border_pattern) then
        return num .. "px" -- Возвращаем без изменений
      end

      -- Проверяем, не находится ли px в letter-spacing свойстве
      local letter_spacing_pattern = "letter%-spacing[^:]*:%s*[^;]*" .. num .. "px"
      if line:match(letter_spacing_pattern) then
        return num .. "px" -- Возвращаем без изменений
      end

      -- Проверяем, не находится ли px в media query
      local media_pattern = "@media[^{]*" .. num .. "px"
      if line:match(media_pattern) then
        return num .. "px" -- Возвращаем без изменений
      end
      local px_value = tonumber(num)
      local rem_value = px_value / 10
      replacements = replacements + 1

      -- Если результат целое число, убираем .0
      if rem_value == math.floor(rem_value) then
        return string.format("%.0frem", rem_value)
      else
        return string.format("%.1frem", rem_value)
      end
    end)

    -- Обновляем строку если она изменилась
    if new_line ~= line then
      vim.api.nvim_buf_set_lines(buf, i - 1, i, false, { new_line })
    end
  end

  -- Показываем результат
  if replacements > 0 then
    vim.notify(string.format("Конвертировано %d значений px в rem", replacements))
  else
    vim.notify("Значения px не найдены")
  end
end

-- Функция для конвертации только выделенного текста
local function px_to_rem_visual()
  -- Получаем выделенный текст
  local start_pos = vim.fn.getpos("'<")
  local end_pos = vim.fn.getpos("'>")

  local start_line = start_pos[2] - 1
  local end_line = end_pos[2] - 1

  -- Получаем выделенные строки
  local lines = vim.api.nvim_buf_get_lines(0, start_line, end_line + 1, false)

  local replacements = 0

  -- Обрабатываем каждую строку
  for i, line in ipairs(lines) do
    local new_line = line:gsub("(%d+%.?%d*)px", function(num)
      local px_value = tonumber(num)
      local rem_value = px_value / 10
      replacements = replacements + 1

      if rem_value == math.floor(rem_value) then
        return string.format("%.0frem", rem_value)
      else
        return string.format("%.1frem", rem_value)
      end
    end)

    if new_line ~= line then
      vim.api.nvim_buf_set_lines(0, start_line + i - 1, start_line + i, false, { new_line })
    end
  end

  if replacements > 0 then
    vim.notify(string.format("Конвертировано %d значений px в rem", replacements))
  else
    vim.notify("Значения px не найдены в выделенном тексте")
  end
end

-- Создаем команды
vim.api.nvim_create_user_command("PxToRem", px_to_rem, {})
vim.api.nvim_create_user_command("PxToRemVisual", px_to_rem_visual, { range = true })

-- Настраиваем keymaps (можешь изменить на свои)
vim.keymap.set("n", "<leader>pr", px_to_rem, { desc = "Convert px to rem (whole file)" })
vim.keymap.set("v", "<leader>pr", px_to_rem_visual, { desc = "Convert px to rem (selection)" })

-- Автокоманда для SCSS/CSS файлов
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "scss", "css", "sass" },
  callback = function()
    vim.keymap.set("n", "<leader>pr", px_to_rem, { desc = "Convert px to rem (whole file)", buffer = true })
    vim.keymap.set("v", "<leader>pr", px_to_rem_visual, { desc = "Convert px to rem (selection)", buffer = true })
  end,
})
