-- Simple CSS property sorter
local M = {}

-- Property order (you can customize this)
local property_order = {
  "content",
  "display", "visibility", "opacity",
  "position", "top", "right", "bottom", "left", "z-index",
  "flex", "flex-direction", "flex-wrap", "flex-flow", "justify-content", "align-items", "align-content", "align-self",
  "grid", "grid-template", "grid-template-rows", "grid-template-columns", "grid-area",
  "width", "min-width", "max-width", "height", "min-height", "max-height",
  "margin", "margin-top", "margin-right", "margin-bottom", "margin-left",
  "padding", "padding-top", "padding-right", "padding-bottom", "padding-left",
  "border", "border-radius", "outline",
  "background", "background-color", "background-image",
  "color", "font", "font-family", "font-size", "font-weight", "line-height",
  "text-align", "text-decoration", "text-transform",
  "overflow", "transform", "transition", "animation"
}

-- Create order map for quick lookup
local order_map = {}
for i, prop in ipairs(property_order) do
  order_map[prop] = i
end

function M.sort_css_properties()
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
  local new_lines = {}
  local in_rule = false
  local current_properties = {}
  local current_non_properties = {}
  local brace_count = 0

  for _, line in ipairs(lines) do
    -- Count opening braces
    local open_braces = 0
    for _ in line:gmatch("{") do
      open_braces = open_braces + 1
    end

    -- Count closing braces
    local close_braces = 0
    for _ in line:gmatch("}") do
      close_braces = close_braces + 1
    end

    -- Check if we're entering a CSS rule (top level)
    if line:match("{%s*$") and brace_count == 0 then
      table.insert(new_lines, line)
      in_rule = true
      current_properties = {}
      current_non_properties = {}
      brace_count = brace_count + open_braces
    -- Check if we're exiting a CSS rule (back to top level)
    elseif in_rule and brace_count + open_braces - close_braces == 0 then
      -- First, sort and add properties
      if #current_properties > 0 then
        table.sort(current_properties, function(a, b)
          local prop_a = a.prop or ""
          local prop_b = b.prop or ""
          local order_a = order_map[prop_a] or 999
          local order_b = order_map[prop_b] or 999
          return order_a < order_b
        end)

        -- Add sorted properties
        for _, prop_line in ipairs(current_properties) do
          table.insert(new_lines, prop_line.line)
        end
      end

      -- Then add non-properties (like @media rules, comments)
      for _, non_prop_line in ipairs(current_non_properties) do
        table.insert(new_lines, non_prop_line)
      end

      -- Add the closing brace
      table.insert(new_lines, line)
      in_rule = false
      current_properties = {}
      current_non_properties = {}
      brace_count = 0
    elseif in_rule then
      -- Update brace count
      brace_count = brace_count + open_braces - close_braces

      -- Check if it's a CSS property (not @media, @include, etc.)
      local prop = line:match("^%s*([%w%-]+)%s*:")
      if prop and not line:match("^%s*@") then
        table.insert(current_properties, {prop = prop, line = line})
      else
        -- Non-property line (@media, @include, comments, nested rules, etc)
        table.insert(current_non_properties, line)
      end
    else
      -- Outside of rules
      table.insert(new_lines, line)
    end
  end

  -- Replace buffer content
  vim.api.nvim_buf_set_lines(0, 0, -1, false, new_lines)
end

return M