return {
  {
    "folke/ts-comments.nvim",
    opts = function()
      return {
        lang = {
          css = "/* %s */",
          scss = "/* %s */",
          sass = "/* %s */",
          less = "/* %s */",
        },
      }
    end,
    config = function(_, opts)
      require("ts-comments").setup(opts)

      -- Override visual mode commenting for CSS/SCSS to use block comments
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "css", "scss", "sass", "less" },
        callback = function()
          vim.keymap.set("v", "gc", function()
            local start_line = vim.fn.line("'<")
            local end_line = vim.fn.line("'>")

            -- Get the selected text
            local lines = vim.api.nvim_buf_get_lines(0, start_line - 1, end_line, false)

            if #lines == 0 then return end

            -- Check if already commented (look for /* at start and */ at end)
            local first_line = lines[1]:match("^%s*")
            local is_commented = lines[1]:match("^%s*/%*") and lines[#lines]:match("%*/%s*$")

            if is_commented then
              -- Uncomment: remove /* from first line and */ from last line
              lines[1] = lines[1]:gsub("^(%s*)/%*%s*", "%1")
              lines[#lines] = lines[#lines]:gsub("%s*%*/%s*$", "")
            else
              -- Comment: add /* to first line and */ to last line
              lines[1] = first_line .. "/*" .. lines[1]:gsub("^%s*", "")
              lines[#lines] = lines[#lines] .. "*/"
            end

            -- Set the modified lines
            vim.api.nvim_buf_set_lines(0, start_line - 1, end_line, false, lines)
          end, { buffer = true, desc = "Toggle block comment" })
        end,
      })
    end,
    event = "VeryLazy",
    enabled = vim.fn.has("nvim-0.10.0") == 1,
  },
}