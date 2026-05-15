-- Кастомный источник для blink.cmp:
-- подсасывает $vars и --vars из <theme>/src/scss/partials/variables.scss
-- работает в любом .scss файле внутри проекта темы.

local M = {}

local cache = {
  path = nil,
  mtime = 0,
  items = {},
}

local function find_variables_file()
  -- Идём вверх от текущего буфера до .../src/scss/partials/variables.scss
  local cur = vim.api.nvim_buf_get_name(0)
  if cur == "" then return nil end
  local dir = vim.fn.fnamemodify(cur, ":p:h")

  for _ = 1, 20 do
    local candidate = dir .. "/src/scss/partials/variables.scss"
    if vim.fn.filereadable(candidate) == 1 then
      return candidate
    end
    local parent = vim.fn.fnamemodify(dir, ":h")
    if parent == dir then break end
    dir = parent
  end
  return nil
end

local function parse(path)
  local items = {}
  local fd = io.open(path, "r")
  if not fd then return items end
  for line in fd:lines() do
    -- $foo: значение;
    local sv_name, sv_val = line:match("^%s*(%$[%w_%-]+)%s*:%s*(.-);")
    if sv_name then
      table.insert(items, {
        label = sv_name,
        insertText = sv_name,
        kind = vim.lsp.protocol.CompletionItemKind.Variable,
        detail = sv_val,
        documentation = { kind = "markdown", value = "```scss\n" .. sv_name .. ": " .. sv_val .. ";\n```" },
      })
    end
    -- --foo: значение;
    local cv_name, cv_val = line:match("^%s*(%-%-[%w_%-]+)%s*:%s*(.-);")
    if cv_name then
      table.insert(items, {
        label = cv_name,
        insertText = cv_name,
        kind = vim.lsp.protocol.CompletionItemKind.Variable,
        detail = cv_val,
        documentation = { kind = "markdown", value = "```css\n" .. cv_name .. ": " .. cv_val .. ";\n```" },
      })
    end
  end
  fd:close()
  return items
end

local function get_items()
  local path = find_variables_file()
  if not path then return {} end
  local stat = vim.uv.fs_stat(path)
  if not stat then return {} end
  if cache.path == path and cache.mtime == stat.mtime.sec then
    return cache.items
  end
  cache.path = path
  cache.mtime = stat.mtime.sec
  cache.items = parse(path)
  return cache.items
end

function M.new()
  return setmetatable({}, { __index = M })
end

function M:get_trigger_characters()
  return { "$", "-" }
end

function M:get_completions(_, callback)
  local line = vim.api.nvim_get_current_line()
  local col = vim.api.nvim_win_get_cursor(0)[2]
  local before = line:sub(1, col)

  -- Показываем только если пользователь начал писать $ или --
  local prefix = before:match("(%$[%w_%-]*)$") or before:match("(%-%-[%w_%-]*)$")
  if not prefix then
    callback({ is_incomplete_forward = false, is_incomplete_backward = false, items = {} })
    return function() end
  end

  local all = get_items()
  local filtered = {}
  local is_dollar = prefix:sub(1, 1) == "$"
  for _, it in ipairs(all) do
    local is_item_dollar = it.label:sub(1, 1) == "$"
    if is_dollar == is_item_dollar then
      table.insert(filtered, it)
    end
  end

  callback({
    is_incomplete_forward = false,
    is_incomplete_backward = false,
    items = filtered,
  })
  return function() end
end

return M
