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

      -- Применяем для HTML, PHP, CSS, SCSS файлов
      if filetype == 'html' or filetype == 'php' or filetype == 'css' or filetype == 'scss' then
        local firstLine = vim.api.nvim_buf_get_lines(0, lnum - 1, lnum, false)[1] or ""

        -- Для HTML и PHP файлов
        if filetype == 'html' or filetype == 'php' then
          local tagMatch = firstLine:match("<%s*([%w%-:]+)")
          if tagMatch and not firstLine:match("<%s*[%w%-:]+[^>]*/>") then -- исключаем самозакрывающиеся теги
            -- Показываем только название тега без атрибутов
            local indent = firstLine:match("^%s*")
            table.insert(newVirtText, { indent .. "<" .. tagMatch, "HTMLFoldTag" })
            table.insert(newVirtText, { " ", nil })
            table.insert(newVirtText, { "...", "Comment" })
            table.insert(newVirtText, { " ", nil })
            table.insert(newVirtText, { ">", "HTMLFoldTag" })
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

    -- Кастомный провайдер для CSS/SCSS фолдинга
    local function custom_fold_provider(bufnr)
      local folds = {}
      local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
      local filetype = vim.api.nvim_buf_get_option(bufnr, 'filetype')

      if filetype == 'css' or filetype == 'scss' or filetype == 'sass' then
        -- CSS/SCSS/SASS логика - только для & селекторов
        local ampersand_starts = {}

        -- Найдем все & селекторы и их закрывающие скобки
        for i, line in ipairs(lines) do
          local trimmed = line:gsub("^%s*", ""):gsub("%s*$", "")
          local indent = #(line:match("^%s*") or "")

          -- Нашли & селектор с открывающей скобкой
          if trimmed:match("^&") and trimmed:match("{%s*$") then
            -- Ищем соответствующую закрывающую скобку на том же уровне отступа
            for j = i + 1, #lines do
              local closing_line = lines[j]
              local closing_trimmed = closing_line:gsub("^%s*", ""):gsub("%s*$", "")
              local closing_indent = #(closing_line:match("^%s*") or "")

              -- Нашли закрывающую скобку на том же уровне
              if closing_trimmed == "}" and closing_indent == indent then
                table.insert(folds, {startLine = i - 1, endLine = j - 1})
                break
              end
            end
          end
        end
      end

      return folds
    end

    require('ufo').setup({
      fold_virt_text_handler = fold_text_handler,
      provider_selector = function(bufnr, filetype, buftype)
        -- Используем treesitter для PHP и HTML - он лучше понимает структуру
        if filetype == 'php' or filetype == 'html' then
          return { 'treesitter', 'indent' }
        end
        -- Кастомный провайдер только для CSS/SCSS с & селекторами
        if filetype == 'css' or filetype == 'scss' or filetype == 'sass' then
          return custom_fold_provider
        end
        -- Для остальных файлов - treesitter
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

    -- Автофолдинг для & селекторов при открытии CSS файлов
    vim.api.nvim_create_autocmd("BufReadPost", {
      pattern = {"*.css", "*.scss", "*.sass"},
      callback = function()
        vim.defer_fn(function()
          -- Закрываем только & селекторы, оставляя главные классы открытыми
          local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
          for i, line in ipairs(lines) do
            local trimmed = line:gsub("^%s+", ""):gsub("%s+$", "")
            if trimmed:match("^&") and trimmed:match("{%s*$") then
              pcall(function()
                vim.api.nvim_win_set_cursor(0, {i, 0})
                vim.cmd("silent! normal! zc")
              end)
            end
          end
        end, 200)
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
