return {
  -- bufferline with move support
  {
    "akinsho/bufferline.nvim",
    event = "VeryLazy",
    dependencies = "nvim-tree/nvim-web-devicons",
    enabled = true,
    opts = {
      options = {
        mode = "buffers",
        themable = true,
        numbers = "none",
        close_command = "bdelete! %d",
        right_mouse_command = "bdelete! %d",
        left_mouse_command = "buffer %d",
        middle_mouse_command = nil,
        indicator = {
          icon = "▎",
          style = "icon",
        },
        buffer_close_icon = "",
        modified_icon = "●",
        close_icon = "",
        left_trunc_marker = "",
        right_trunc_marker = "",
        max_name_length = 18,
        max_prefix_length = 15,
        tab_size = 18,
        diagnostics = false,
        show_buffer_icons = true,
        show_buffer_close_icons = true,
        show_close_icon = true,
        show_tab_indicators = true,
        persist_buffer_sort = true,
        separator_style = "thin",
        enforce_regular_tabs = false,
        always_show_bufferline = true,
        sort_by = "id",
      },
    },
    config = function(_, opts)
      require("bufferline").setup(opts)

      -- Smart buffer delete that doesn't close window
      local function smart_bdelete()
        local bufnr = vim.api.nvim_get_current_buf()
        local buffers = vim.fn.getbufinfo({ buflisted = 1 })

        -- If there's more than one buffer, switch to another before deleting
        if #buffers > 1 then
          vim.cmd("bp")
        else
          -- If this is the last buffer, create a new empty one first
          vim.cmd("enew")
        end

        -- Delete the original buffer
        vim.api.nvim_buf_delete(bufnr, { force = false })
      end

      -- Keymaps
      vim.keymap.set("n", "<Tab>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next buffer" })
      vim.keymap.set("n", "<S-Tab>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Previous buffer" })
      vim.keymap.set("n", "<leader>x", smart_bdelete, { desc = "Close buffer" })
      vim.keymap.set("n", "<leader>qo", smart_bdelete, { desc = "Delete buffer" })
    end,
  },
}