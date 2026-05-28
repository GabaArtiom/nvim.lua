-- Treesitter-based HTML/JSX tag text object for mini.ai.
--
-- Replaces mini.ai's default pattern-based `t` so that `cit` / `dit` / `vat`
-- work correctly even when a tag's attributes contain embedded PHP
-- (`href="tel:<?php echo $x; ?>"`). The default Lua-pattern matcher chokes on
-- the literal `<` / `>` inside `<?php ?>` and ends up selecting the wrong
-- element (e.g. the whole enclosing `<li>` plus its `>`).

-- A node counts as a tag if its type mentions "element"
-- (html `element`/`script_element`/`style_element`, jsx `*_element`).
local function is_element(node)
  return node:type():find("element") ~= nil
end

-- First child whose type contains any of the given substrings.
local function child_by_type(node, substrings)
  for child in node:iter_children() do
    local t = child:type()
    for _, s in ipairs(substrings) do
      if t:find(s, 1, true) then
        return child
      end
    end
  end
end

-- Every tag-like node containing the (0-based) cursor position, across all
-- injected HTML/JSX trees, ordered innermost-first.
local function enclosing_elements(row, col)
  local ok, parser = pcall(vim.treesitter.get_parser, 0)
  if not ok or not parser then
    return {}
  end
  pcall(parser.parse, parser, true)

  local found = {}
  local function visit(ltree)
    for _, tree in pairs(ltree:trees()) do
      local root = tree:root()
      if vim.treesitter.is_in_node_range(root, row, col) then
        local node = root:named_descendant_for_range(row, col, row, col)
        while node do
          if is_element(node) and vim.treesitter.is_in_node_range(node, row, col) then
            found[#found + 1] = node
          end
          node = node:parent()
        end
      end
    end
    for _, child in pairs(ltree:children()) do
      visit(child)
    end
  end
  visit(parser)
  return found
end

-- Last 1-based column of a line (the position of its final character).
local function last_col(lnum)
  return math.max(vim.fn.col({ lnum, "$" }) - 1, 1)
end

-- Convert a treesitter element node into a mini.ai region (1-based, `to`
-- inclusive). Returns nil when an `i` region has no inside (self-closing tag).
local function to_region(node, ai_type)
  if ai_type == "a" then
    local sr, sc, er, ec = node:range()
    if ec == 0 then -- node ends exactly at a line start: back up one line
      er, ec = er - 1, last_col(er)
    end
    return { from = { line = sr + 1, col = sc + 1 }, to = { line = er + 1, col = ec } }
  end

  local open = child_by_type(node, { "start_tag", "opening_element" })
  local close = child_by_type(node, { "end_tag", "closing_element" })
  if not open or not close then
    return nil -- self-closing / malformed: nothing inside
  end

  local _, _, or_, oc = open:range() -- inside starts right after the `>`
  local cr, cc = close:range() -- inside ends right before the `</`
  local from = { line = or_ + 1, col = oc + 1 }
  local to
  if cc == 0 then
    to = { line = cr, col = last_col(cr) }
  else
    to = { line = cr + 1, col = cc }
  end

  if from.line > to.line or (from.line == to.line and from.col > to.col) then
    return { from = from, to = nil } -- empty element (`<a></a>`)
  end
  return { from = from, to = to }
end

local function pos_le(a, b)
  return a.line < b.line or (a.line == b.line and a.col <= b.col)
end

-- True when `outer` strictly contains `inner` (equal regions don't count).
local function region_contains(outer, inner)
  local o_to = outer.to or outer.from
  local i_to = inner.to or inner.from
  if not (pos_le(outer.from, inner.from) and pos_le(i_to, o_to)) then
    return false
  end
  return not (
    outer.from.line == inner.from.line
    and outer.from.col == inner.from.col
    and o_to.line == i_to.line
    and o_to.col == i_to.col
  )
end

-- Look on `row` for a tag that opens at or after `col` (0-based). Returns the
-- 0-based column right after that tag's `>` (i.e. a position guaranteed to sit
-- inside the tag's inside-region), or nil if none found on this line.
local function inline_tag_inside_col(row, col)
  local line = vim.api.nvim_buf_get_lines(0, row, row + 1, false)[1] or ""
  local from = col + 1
  while true do
    local lt = line:find("<", from, true)
    if not lt then return nil end
    if line:sub(lt + 1, lt + 1) ~= "/" then
      local gt = line:find(">", lt + 1, true)
      if gt then
        return gt -- 0-based column of the byte just after `>`
      end
    end
    from = lt + 1
  end
end

-- mini.ai custom textobject. Returns a single region (which mini.ai uses
-- verbatim), so counts and consecutive `vit` expansion are handled here:
-- each step picks the smallest tag region that strictly contains the
-- previous reference (cursor for `cit`, current selection for repeated `vit`).
local function tag_textobject(ai_type, _, opts)
  local pos = vim.api.nvim_win_get_cursor(0)
  local row, col = pos[1] - 1, pos[2]

  -- Vim-style lookahead: if the cursor sits just before a tag opening on the
  -- current line (e.g. cursor on `1` in `1<div></div>`), pretend the cursor
  -- is inside that tag instead of escalating to a parent that started on a
  -- previous line. Only do this for the initial cursor-point reference —
  -- repeated `vit` expansion must keep growing the existing selection.
  local ref = opts.reference_region
  local is_point = ref and ref.from
    and (not ref.to or (ref.from.line == ref.to.line and ref.from.col == ref.to.col))

  local nodes = enclosing_elements(row, col)

  -- Vim-style lookahead for the initial cursor-point reference. If the cursor
  -- is on a line that touches an enclosing element's start_tag or end_tag
  -- (anywhere — inside the tag itself, or before/after it on the same line),
  -- snap the reference into that element's inside-region so `cit` targets it
  -- instead of escalating to a parent that started on an earlier line.
  -- Falls back to a forward `<…>` scan on the cursor line for cases where the
  -- cursor isn't inside any element at all.
  -- Repeated `vit` expansion (non-point reference) is left untouched so the
  -- existing selection keeps growing outward.
  if is_point then
    local advanced_ref
    for _, node in ipairs(nodes) do
      local region = to_region(node, "i")
      if region and region.to then
        local open = child_by_type(node, { "start_tag", "opening_element" })
        local close = child_by_type(node, { "end_tag", "closing_element" })
        local touches = false
        if open then
          local osr, _, oer = open:range()
          if row >= osr and row <= oer then touches = true end
        end
        if not touches and close then
          local csr, _, cer = close:range()
          if row >= csr and row <= cer then touches = true end
        end
        if touches then
          advanced_ref = { from = region.from }
          break
        end
      end
    end
    if not advanced_ref then
      local fwd = inline_tag_inside_col(row, col)
      if fwd then
        advanced_ref = { from = { line = row + 1, col = fwd + 1 } }
      end
    end
    if advanced_ref then
      row = advanced_ref.from.line - 1
      col = advanced_ref.from.col - 1
      opts.reference_region = advanced_ref
      nodes = enclosing_elements(row, col)
    end
  end

  local regions = {}
  for _, node in ipairs(nodes) do
    local region = to_region(node, ai_type)
    if region then
      regions[#regions + 1] = region
    end
  end
  if #regions == 0 then
    return nil
  end

  local ref = opts.reference_region
  local result
  for _ = 1, opts.n_times or 1 do
    local best
    for _, region in ipairs(regions) do
      if region_contains(region, ref) and (not best or region_contains(best, region)) then
        best = region
      end
    end
    if not best then
      break
    end
    result = best
    ref = best
  end
  return result
end

return {
  "nvim-mini/mini.ai",
  opts = function(_, opts)
    opts.custom_textobjects = opts.custom_textobjects or {}
    opts.custom_textobjects.t = tag_textobject
  end,
}
