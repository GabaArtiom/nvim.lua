return {
  {
    "folke/ts-comments.nvim",
    opts = {
      lang = {
        css = "/* %s */",
        scss = "/* %s */",
        sass = "/* %s */",
        less = "/* %s */",
      },
    },
    event = "VeryLazy",
    enabled = vim.fn.has("nvim-0.10.0") == 1,
  },
}