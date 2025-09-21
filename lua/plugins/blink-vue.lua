return {
  "saghen/blink.cmp",
  opts = {
    sources = {
      providers = {
        lsp = {
          score_offset = 100, -- Boost LSP completions (imports, functions)
        },
      },
      transform_items = function(ctx, items)
        -- Deduplicate items first
        local seen = {}
        local deduplicated = {}

        for _, item in ipairs(items) do
          local label = item.label or ""
          if not seen[label] then
            seen[label] = true
            table.insert(deduplicated, item)
          end
        end

        -- Only filter in Vue files and only when inside template tags
        if vim.bo.filetype == 'vue' then
          local line = vim.api.nvim_get_current_line()
          local col = vim.api.nvim_win_get_cursor(0)[2]
          local before_cursor = line:sub(1, col)

          -- Check if we're inside template section AND inside an opening tag
          local in_template = false
          local lines = vim.api.nvim_buf_get_lines(0, 0, vim.api.nvim_win_get_cursor(0)[1], false)
          for _, template_line in ipairs(lines) do
            if template_line:match("^%s*<template") then
              in_template = true
              break
            end
          end

          -- Only filter if we're in template AND inside an opening tag
          if in_template and before_cursor:match("<%w+[^>]*$") then
            return vim.tbl_filter(function(item)
              local label = item.label or ""
              local kind = item.kind

              -- Block HTML tag snippets (simple lowercase words)
              if (kind == vim.lsp.protocol.CompletionItemKind.Snippet or
                  kind == vim.lsp.protocol.CompletionItemKind.Text) and
                 label:match("^[a-z]+$") and not (
                 label == 'class' or label == 'id' or label == 'style' or
                 label == 'ref' or label == 'key' or label == 'slot' or label == 'is') then
                return false
              end

              -- Allow both v-if and vIf versions

              return true
            end, deduplicated)
          end
        end

        return deduplicated
      end,
    },
    completion = {
      list = {
        selection = { preselect = true, auto_insert = true },
      },
    },
  },
}