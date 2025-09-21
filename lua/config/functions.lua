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


-- Setup function to register keymaps
function M.setup()
  local map = vim.keymap.set

  -- BEM class helper
  map("n", "<leader>vs", M.copy_bem_class, { desc = "Скопировать BEM-класс в регистр i" })
end

return M