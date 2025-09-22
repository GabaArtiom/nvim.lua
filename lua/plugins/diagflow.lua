return {
  {
    "dgagn/diagflow.nvim",
    event = "LspAttach",
    opts = {
      enable = true,
      max_width = 60,
      max_height = 10,
      severity_colors = {
        error = "DiagnosticFloatingError",
        warning = "DiagnosticFloatingWarn",
        info = "DiagnosticFloatingInfo",
        hint = "DiagnosticFloatingHint",
      },
      format = function(diagnostic)
        return diagnostic.message
      end,
      gap_size = 1,
      scope = 'cursor',
      padding_top = 0,
      padding_right = 0,
      text_align = 'right',
      placement = 'top',
      inline_padding_left = 0,
      update_event = { 'DiagnosticChanged', 'BufReadPost' },
      render_event = { 'DiagnosticChanged', 'CursorMoved' },
      show_sign = false,
      show_borders = false,
    },
    config = function(_, opts)
      require('diagflow').setup(opts)
    end,
  },
}