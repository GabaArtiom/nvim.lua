return {
  {
    "folke/noice.nvim",
    opts = {
      lsp = {
        hover = {
          silent = true, -- Don't show "No information available" notifications
        },
        signature = {
          enabled = false, -- Disable signature help notifications completely
        },
      },
    },
  },
}