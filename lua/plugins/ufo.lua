-- ~/.config/nvim/lua/plugins/ufo.lua
-- UFO с превью содержимого при сворачивании

return {
  "kevinhwang91/nvim-ufo",
  dependencies = "kevinhwang91/promise-async",
  event = "BufReadPost",
  keys = {
    { "zR", function() require("ufo").openAllFolds() end,               desc = "Open all folds" },
    { "zM", function() require("ufo").closeAllFolds() end,              desc = "Close all folds" },
    { "za", "za",                                                       desc = "Toggle fold" },
    { "zp", function() require("ufo").peekFoldedLinesUnderCursor() end, desc = "Peek fold" },
  },
  config = function()
    vim.o.foldcolumn = '1'
    vim.o.foldlevel = 99
    vim.o.foldlevelstart = 99
    vim.o.foldenable = true

    -- Сохранение состояния закрытых фолдов (отключено)
    -- local function save_folds()
    --   local folds = {}
    --   local line_count = vim.api.nvim_buf_line_count(0)
    --   for lnum = 1, line_count do
    --     if vim.fn.foldclosed(lnum) == lnum then
    --       table.insert(folds, lnum)
    --     end
    --   end
    --   return folds
    -- end

    -- local function restore_folds(folds)
    --   for _, lnum in ipairs(folds) do
    --     vim.api.nvim_win_set_cursor(0, {lnum, 0})
    --     pcall(vim.cmd, "normal! zc")
    --   end
    -- end

    -- local saved_folds = {}

    -- vim.api.nvim_create_autocmd("BufWritePre", {
    --   pattern = "*",
    --   callback = function()
    --     local bufnr = vim.api.nvim_get_current_buf()
    --     saved_folds[bufnr] = save_folds()
    --   end,
    -- })

    -- vim.api.nvim_create_autocmd("BufWritePost", {
    --   pattern = "*",
    --   callback = function()
    --     vim.schedule(function()
    --       local bufnr = vim.api.nvim_get_current_buf()
    --       if saved_folds[bufnr] then
    --         restore_folds(saved_folds[bufnr])
    --         saved_folds[bufnr] = nil
    --       end
    --     end)
    --   end,
    -- })

    -- Восстановление фолдов при открытии файла (отключено)
    -- vim.api.nvim_create_autocmd("BufReadPost", {
    --   pattern = "*",
    --   callback = function()
    --     vim.cmd("silent! loadview")
    --   end,
    -- })

    -- Функция для показа HTML тегов как <tag ... >
    local function fold_text_handler(virtText, lnum, endLnum, width, truncate)
      local newVirtText = {}
      local filetype = vim.api.nvim_buf_get_option(0, 'filetype')

      -- Применяем для HTML, PHP, Vue, CSS, SCSS, JS, TS файлов
      if filetype == 'html' or filetype == 'php' or filetype == 'vue' or filetype == 'css' or filetype == 'scss' or
         filetype == 'javascript' or filetype == 'typescript' or filetype == 'javascriptreact' or filetype == 'typescriptreact' then
        local firstLine = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""

        -- Для HTML, PHP и Vue файлов
        if filetype == 'html' or filetype == 'php' or filetype == 'vue' then
          local tagMatch = firstLine:match("<%s*([%w%-:]+)")
          if tagMatch and not firstLine:match("<%s*[%w%-:]+[^>]*/>") then -- исключаем самозакрывающиеся теги
            local indent = firstLine:match("^%s*")

            -- Собираем все строки до закрывающей скобки тега
            local fullTag = firstLine
            if not firstLine:match(">") then
              -- Тег многострочный, ищем закрывающую скобку
              for i = lnum, math.min(lnum + 10, endLnum) do
                local line = vim.api.nvim_buf_get_lines(0, i, i + 1, false)[1]
                if line then
                  fullTag = fullTag .. " " .. line
                  if line:match(">") then
                    break
                  end
                end
              end
            end

            -- Извлекаем class или id из полного тега
            local classMatch = fullTag:match('class%s*=%s*["\']([^"\']+)["\']')
            local idMatch = fullTag:match('id%s*=%s*["\']([^"\']+)["\']')

            -- Формируем строку фолда
            local foldText = indent .. "<" .. tagMatch

            if classMatch then
              -- Берем только первый класс если их несколько
              local firstClass = classMatch:match("^(%S+)")
              table.insert(newVirtText, { foldText, "HTMLFoldTag" })
              table.insert(newVirtText, { ' class="' .. firstClass .. '"', "String" })
              table.insert(newVirtText, { " ", nil })
              table.insert(newVirtText, { "...", "Comment" })
              table.insert(newVirtText, { " ", nil })
              table.insert(newVirtText, { ">", "HTMLFoldTag" })
            elseif idMatch then
              table.insert(newVirtText, { foldText, "HTMLFoldTag" })
              table.insert(newVirtText, { ' id="' .. idMatch .. '"', "String" })
              table.insert(newVirtText, { " ", nil })
              table.insert(newVirtText, { "...", "Comment" })
              table.insert(newVirtText, { " ", nil })
              table.insert(newVirtText, { ">", "HTMLFoldTag" })
            else
              -- Если нет class или id, показываем просто тег
              table.insert(newVirtText, { foldText, "HTMLFoldTag" })
              table.insert(newVirtText, { " ", nil })
              table.insert(newVirtText, { "...", "Comment" })
              table.insert(newVirtText, { " ", nil })
              table.insert(newVirtText, { ">", "HTMLFoldTag" })
            end

            return newVirtText
          end
        end

        -- Для CSS, SCSS и SASS файлов
        if filetype == 'css' or filetype == 'scss' or filetype == 'sass' then
          local indent = firstLine:match("^%s*") or ""

          -- Собираем все селекторы (включая многострочные через запятую)
          local fullSelector = ""
          local currentLine = firstLine

          -- Если первая строка заканчивается на запятую, собираем селекторы из следующих строк
          if currentLine:match(",%s*$") then
            fullSelector = currentLine:gsub("^%s*", ""):gsub("%s*$", "")

            -- Читаем следующие строки до тех пор, пока не найдем открывающую скобку
            for i = lnum, math.min(lnum + 5, endLnum) do
              local line = vim.api.nvim_buf_get_lines(0, i, i + 1, false)[1]
              if line and i > lnum - 1 then
                local trimmed = line:gsub("^%s*", ""):gsub("%s*$", "")
                if trimmed:match("{") then
                  -- Нашли строку с открывающей скобкой
                  local selectorPart = trimmed:match("^([^{]+)")
                  if selectorPart then
                    fullSelector = fullSelector .. " " .. selectorPart:gsub("%s*$", "")
                  end
                  break
                elseif trimmed:match(",%s*$") then
                  -- Еще один селектор через запятую
                  fullSelector = fullSelector .. " " .. trimmed
                end
              end
            end

            table.insert(newVirtText, { indent .. fullSelector, "CSSFoldSelector" })
            table.insert(newVirtText, { " { ", nil })
            table.insert(newVirtText, { "...", "Comment" })
            table.insert(newVirtText, { " }", nil })
            return newVirtText
          end

          -- Обычный случай: селектор с открывающей скобкой на одной строке
          local cssSelector = firstLine:match("^%s*([^{]+)%s*{%s*$")
          if cssSelector then
            table.insert(newVirtText, { indent .. cssSelector:gsub("^%s*", ""):gsub("%s*$", ""), "CSSFoldSelector" })
            table.insert(newVirtText, { " { ", nil })
            table.insert(newVirtText, { "...", "Comment" })
            table.insert(newVirtText, { " }", nil })
            return newVirtText
          end
        end

        -- Для JavaScript и TypeScript файлов
        if filetype == 'javascript' or filetype == 'typescript' or filetype == 'javascriptreact' or filetype == 'typescriptreact' then
          local indent = firstLine:match("^%s*") or ""

          -- Обработка функций: function name() { ... } или export function name() { ... }
          local exportPrefix = firstLine:match("^%s*(export%s+default%s+)") or firstLine:match("^%s*(export%s+)") or ""
          local funcMatch = firstLine:match("function%s+([%w_]+)%s*%(")
          if funcMatch then
            table.insert(newVirtText, { indent .. exportPrefix .. "function " .. funcMatch .. "() { ", "Function" })
            table.insert(newVirtText, { "...", "Comment" })
            table.insert(newVirtText, { " }", nil })
            return newVirtText
          end

          -- Обработка стрелочных функций: const name = () => { ... }
          local arrowMatch = firstLine:match("^%s*const%s+([%w_]+)%s*=%s*%(")
          if arrowMatch then
            table.insert(newVirtText, { indent .. "const " .. arrowMatch .. " = () => { ", "Function" })
            table.insert(newVirtText, { "...", "Comment" })
            table.insert(newVirtText, { " }", nil })
            return newVirtText
          end

          -- Обработка методов объектов: obj.method("arg", { ... })
          local methodMatch = firstLine:match("^%s*([%w_]+)%.([%w_]+)%(")
          if methodMatch then
            local objName = methodMatch
            local methodName = firstLine:match("%.([%w_]+)%(")

            -- Подсчитываем элементы только первого уровня
            local lines = vim.api.nvim_buf_get_lines(0, lnum - 1, endLnum, false)
            local firstLineIndent = #(lines[1]:match("^%s*") or "")
            local baseIndent = nil
            local elementCount = 0

            for i, line in ipairs(lines) do
              if i > 1 then -- Пропускаем первую строку
                local currentIndent = #(line:match("^%s*") or "")

                -- Определяем базовый отступ (первый ключ после {)
                if not baseIndent and line:match("^%s*[%w_]+:") then
                  baseIndent = currentIndent
                end

                -- Считаем только ключи с базовым отступом (первый уровень)
                if baseIndent and currentIndent == baseIndent and line:match("^%s*[%w_]+:") then
                  elementCount = elementCount + 1
                end
              end
            end

            table.insert(newVirtText, { indent .. objName .. "." .. methodName .. "(", "Function" })
            if elementCount > 0 then
              table.insert(newVirtText, { "..., [" .. elementCount .. " element" .. (elementCount > 1 and "s" or "") .. "...]", "Number" })
            else
              table.insert(newVirtText, { "...", "Comment" })
            end
            table.insert(newVirtText, { ");", nil })
            return newVirtText
          end

          -- Обработка объектов/массивов: let name = { ... } или let name = [ ... ]
          local objMatch = firstLine:match("^%s*let%s+([%w_]+)%s*=%s*[%w%.]+%(+%s*{")
          local objMatch2 = firstLine:match("^%s*const%s+([%w_]+)%s*=%s*[%w%.]+%(+%s*{")
          local objMatch3 = firstLine:match("^%s*let%s+([%w_]+)%s*=%s*{")
          local objMatch4 = firstLine:match("^%s*const%s+([%w_]+)%s*=%s*{")

          if objMatch or objMatch2 or objMatch3 or objMatch4 then
            local varName = objMatch or objMatch2 or objMatch3 or objMatch4

            -- Подсчитываем элементы только первого уровня
            local lines = vim.api.nvim_buf_get_lines(0, lnum - 1, endLnum, false)
            local firstLineIndent = #(lines[1]:match("^%s*") or "")
            local baseIndent = nil
            local elementCount = 0

            for i, line in ipairs(lines) do
              if i > 1 then -- Пропускаем первую строку
                local currentIndent = #(line:match("^%s*") or "")

                -- Определяем базовый отступ (первый ключ после {)
                if not baseIndent and line:match("^%s*[%w_]+:") then
                  baseIndent = currentIndent
                end

                -- Считаем только ключи с базовым отступом (первый уровень)
                if baseIndent and currentIndent == baseIndent and line:match("^%s*[%w_]+:") then
                  elementCount = elementCount + 1
                end
              end
            end

            -- Определяем тип переменной (let/const)
            local varType = firstLine:match("^%s*(let)%s+") or firstLine:match("^%s*(const)%s+")

            -- Определяем вызов функции если есть
            local funcCall = firstLine:match("=%s*([%w%.]+)%(")

            if funcCall then
              table.insert(newVirtText, { indent .. varType .. " " .. varName .. " = " .. funcCall .. "(", "Identifier" })
              if elementCount > 0 then
                table.insert(newVirtText, { "[" .. elementCount .. " element" .. (elementCount > 1 and "s" or "") .. "...]", "Number" })
              else
                table.insert(newVirtText, { "...", "Comment" })
              end
              table.insert(newVirtText, { ");", nil })
            else
              table.insert(newVirtText, { indent .. varType .. " " .. varName .. " = { ", "Identifier" })
              if elementCount > 0 then
                table.insert(newVirtText, { elementCount .. " element" .. (elementCount > 1 and "s" or "") .. " ", "Number" })
              else
                table.insert(newVirtText, { "...", "Comment" })
              end
              table.insert(newVirtText, { "}", nil })
            end
            return newVirtText
          end
        end
      end

      -- Для остальных случаев используем стандартную логику
      for _, chunk in ipairs(virtText) do
        table.insert(newVirtText, chunk)
      end

      -- Дополнительная информация только для HTML/PHP/Vue файлов
      if filetype == 'html' or filetype == 'php' or filetype == 'vue' then
        local foldedLines = endLnum - lnum
        if foldedLines > 0 then
          -- Читаем все строки фолда
          local allLines = vim.api.nvim_buf_get_lines(0, lnum + 1, endLnum, false)

          -- Ищем первую содержательную строку
          local firstContent = ""
          for _, line in ipairs(allLines) do
            local trimmed = line:gsub("^%s*", ""):gsub("%s*$", "")
            if trimmed ~= "" and not trimmed:match("^</") then
              firstContent = trimmed
              break
            end
          end

          -- Ищем закрывающий тег (последняя строка)
          local closingTag = ""
          if #allLines > 0 then
            local lastLine = allLines[#allLines]:gsub("^%s*", ""):gsub("%s*$", "")
            if lastLine:match("^</") then
              closingTag = lastLine
            end
          end

          -- Добавляем в одну строку: --- содержимое --- закрывающий_тег
          if #firstContent > 0 then
            table.insert(newVirtText, { " --- ", "Comment" })
            -- Обрезаем содержимое если слишком длинное
            if #firstContent > 50 then
              firstContent = firstContent:sub(1, 50) .. "..."
            end
            table.insert(newVirtText, { firstContent, "String" })
            table.insert(newVirtText, { " --- ", "Comment" })
          end

          if #closingTag > 0 then
            table.insert(newVirtText, { closingTag, "Tag" })
          end
        end
      end

      return newVirtText
    end

    require('ufo').setup({
      fold_virt_text_handler = fold_text_handler,
      provider_selector = function(bufnr, filetype, buftype)
        -- Используем treesitter для всех файлов - он лучше понимает структуру
        return { 'treesitter', 'indent' }
      end,
      preview = {
        win_config = {
          border = { "┌", "─", "┐", "│", "┘", "─", "└", "│" },
          winhighlight = "Normal:Folded",
        },
        mappings = {
          scrollU = "<C-u>",
          scrollD = "<C-d>",
        },
      },
    })

    -- Автофолдинг для вложенных селекторов при открытии CSS/SCSS файлов (отключено)
    -- vim.api.nvim_create_autocmd("BufReadPost", {
    --   pattern = {"*.css", "*.scss", "*.sass"},
    --   callback = function()
    --     vim.defer_fn(function()
    --       -- Сначала открываем все фолды
    --       vim.cmd("silent! normal! zR")
    --
    --       -- Затем закрываем только вложенные блоки
    --       local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
    --       local line_count = vim.api.nvim_buf_line_count(0)
    --
    --       -- Проходим по всем строкам и ищем вложенные блоки
    --       for i = 1, line_count do
    --         local line = lines[i] or ""
    --         local indent_spaces = line:match("^(%s*)")
    --         local indent_level = #indent_spaces
    --
    --         -- Закрываем блоки с отступом >= 2 пробела/1 таб
    --         if indent_level >= 2 then
    --           local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
    --
    --           -- Проверяем что это начало блока (селектор с {)
    --           if trimmed:match("{%s*$") or trimmed:match("^[^{}]+%s*{%s*$") then
    --             -- Проверяем что для этой строки есть фолд
    --             if vim.fn.foldclosed(i) == -1 then
    --               pcall(function()
    --                 vim.api.nvim_win_set_cursor(0, {i, 0})
    --                 vim.cmd("silent! normal! zc")
    --               end)
    --             end
    --           end
    --         end
    --       end
    --
    --       -- Возвращаем курсор в начало
    --       vim.api.nvim_win_set_cursor(0, {1, 0})
    --     end, 300)
    --   end,
    -- })

    -- Красивые цвета
    vim.api.nvim_set_hl(0, "Folded", {
      fg = "#7c8f8f",
      bg = "#1e2030",
      italic = true,
    })

    -- Цвета для фолдов (наследуются от темы)
    vim.api.nvim_set_hl(0, "HTMLFoldTag", { link = "Identifier" })
    vim.api.nvim_set_hl(0, "CSSFoldSelector", { link = "Identifier" })
  end,
}
