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
      presets = {
        command_palette = true,
        bottom_search = false, -- Disable bottom search, we use popup instead
      },
      cmdline = {
        enabled = true,
        view = "cmdline_popup",
        format = {
          cmdline = { pattern = "^:", icon = "\u{e62b}", lang = "vim", view = "cmdline_popup" },
          search_down = { kind = "search", pattern = "^/", icon = "\u{f002} ", lang = "regex", view = "cmdline_popup" },
          search_up = { kind = "search", pattern = "^%?", icon = "\u{f002} ", lang = "regex", view = "cmdline_popup" },
          filter = { pattern = "^:%s*!", icon = "$", lang = "bash", view = "cmdline_popup" },
          lua = { pattern = { "^:%s*lua%s+", "^:%s*lua%s*=%s*", "^:%s*=%s*" }, icon = "\u{e620}", lang = "lua", view = "cmdline_popup" },
          help = { pattern = "^:%s*he?l?p?%s+", icon = "\u{f059}", view = "cmdline_popup" },
          input = { icon = "\u{f49b} ", view = "cmdline_popup" },
        },
      },
      views = {
        cmdline_popup = {
          position = {
            row = "50%",
            col = "50%",
          },
          size = {
            width = 60,
            height = "auto",
          },
        },
      },
    },
  },
}