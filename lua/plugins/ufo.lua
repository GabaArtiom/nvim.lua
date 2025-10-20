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

    -- Сохранение состояния закрытых фолдов
    local function save_folds()
      local folds = {}
      local line_count = vim.api.nvim_buf_line_count(0)
      for lnum = 1, line_count do
        if vim.fn.foldclosed(lnum) == lnum then
          table.insert(folds, lnum)
        end
      end
      return folds
    end

    local function restore_folds(folds)
      for _, lnum in ipairs(folds) do
        vim.api.nvim_win_set_cursor(0, {lnum, 0})
        pcall(vim.cmd, "normal! zc")
      end
    end

    local saved_folds = {}

    vim.api.nvim_create_autocmd("BufWritePre", {
      pattern = "*",
      callback = function()
        local bufnr = vim.api.nvim_get_current_buf()
        saved_folds[bufnr] = save_folds()
      end,
    })

    vim.api.nvim_create_autocmd("BufWritePost", {
      pattern = "*",
      callback = function()
        vim.schedule(function()
          local bufnr = vim.api.nvim_get_current_buf()
          if saved_folds[bufnr] then
            restore_folds(saved_folds[bufnr])
            saved_folds[bufnr] = nil
          end
        end)
      end,
    })

    -- Восстановление фолдов при открытии файла
    vim.api.nvim_create_autocmd("BufReadPost", {
      pattern = "*",
      callback = function()
        vim.cmd("silent! loadview")
      end,
    })

    -- Функция для показа HTML тегов как <tag ... >
    local function fold_text_handler(virtText, lnum, endLnum, width, truncate)
      local newVirtText = {}
      local filetype = vim.api.nvim_buf_get_option(0, 'filetype')

      -- Применяем для HTML, PHP, Vue, CSS, SCSS файлов
      if filetype == 'html' or filetype == 'php' or filetype == 'vue' or filetype == 'css' or filetype == 'scss' then
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
          -- Проверяем CSS селекторы
          local cssSelector = firstLine:match("^%s*([^{]+)%s*{%s*$")
          if cssSelector then
            local indent = firstLine:match("^%s*")
            table.insert(newVirtText, { indent .. cssSelector:gsub("^%s*", ""):gsub("%s*$", ""), "CSSFoldSelector" })
            table.insert(newVirtText, { " { ", nil })
            table.insert(newVirtText, { "...", "Comment" })
            table.insert(newVirtText, { " }", nil })
            return newVirtText
          end
        end
      end

      -- Для остальных случаев используем стандартную логику
      for _, chunk in ipairs(virtText) do
        table.insert(newVirtText, chunk)
      end

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

    -- Автофолдинг для вложенных селекторов при открытии CSS/SCSS файлов
    vim.api.nvim_create_autocmd("BufReadPost", {
      pattern = {"*.css", "*.scss", "*.sass"},
      callback = function()
        vim.defer_fn(function()
          -- Сначала открываем все фолды
          vim.cmd("silent! normal! zR")

          -- Затем закрываем только вложенные блоки
          local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
          local line_count = vim.api.nvim_buf_line_count(0)

          -- Проходим по всем строкам и ищем вложенные блоки
          for i = 1, line_count do
            local line = lines[i] or ""
            local indent_spaces = line:match("^(%s*)")
            local indent_level = #indent_spaces

            -- Закрываем блоки с отступом >= 2 пробела/1 таб
            if indent_level >= 2 then
              local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")

              -- Проверяем что это начало блока (селектор с {)
              if trimmed:match("{%s*$") or trimmed:match("^[^{}]+%s*{%s*$") then
                -- Проверяем что для этой строки есть фолд
                if vim.fn.foldclosed(i) == -1 then
                  pcall(function()
                    vim.api.nvim_win_set_cursor(0, {i, 0})
                    vim.cmd("silent! normal! zc")
                  end)
                end
              end
            end
          end

          -- Возвращаем курсор в начало
          vim.api.nvim_win_set_cursor(0, {1, 0})
        end, 300)
      end,
    })

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
