-- ~/.config/nvim/lua/snippets/js_ts.lua
local ls = require("luasnip")
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

local console = {
  s("cl", {
    t("console.log("),
    i(1, "value"),
    t(");"),
  }),
  s("dqs", {
    t("document.querySelector("),
    i(1, "'selector'"),
    t(");"),
  }),
  s("fun", {
    t("function "),
    i(1), -- имя функции
    t("("),
    i(2), -- аргументы
    t(") {"),
    i(3), -- тело функции
    t("}"),
  }),
}

return {
  javascript = console,
  typescript = console,
  javascriptreact = console,
  typescriptreact = console,
}
