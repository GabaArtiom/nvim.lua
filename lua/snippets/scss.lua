local ls = require("luasnip")
local rep = require("luasnip.extras").rep
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node

local css_scss_snippets = {

  s("mc5", {
    t("@media screen and (max-width: 576px) {"),
    t({ "", "  " }),
    i(1),
    t({ "", "}" }),
  }),

  s("mc7", {
    t("@media screen and (max-width: 768px) {"),
    t({ "", "  " }),
    i(1),
    t({ "", "}" }),
  }),

  s("mc9", {
    t("@media screen and (max-width: 992px) {"),
    t({ "", "  " }),
    i(1),
    t({ "", "}" }),
  }),

  s("mc12", {
    t("@media screen and (max-width: 1200px) {"),
    t({ "", "  " }),
    i(1),
    t({ "", "}" }),
  }),

  s("mcus", {
    t("@media screen and (max-width: "),
    i(1),
    t({ "px) {", "  " }),
    i(2),
    t({ "", "}" }),
  }),

  s("pa", {
    t({
      "position: absolute;",
      "top: 0;",
      "left: 0;",
      "display: block;",
      "width: 100%;",
      "height: 100%;",
    }),
  }),

  s("dfb", {
    t({
      "display: flex;",
      "justify-content: space-between;",
    }),
  }),

  s("dfc", {
    t({
      "display: flex;",
      "justify-content: center;",
      "align-items: center;",
    }),
  }),

  s("vr", {
    t("var(--"), i(1), t(")"),
  }),

  -- Padding block/inline
  s("pbl", {
    t("padding-block: "), i(1), t(";"),
  }),

  s("pin", {
    t("padding-inline: "), i(1), t(";"),
  }),

  -- Margin block/inline
  s("mbl", {
    t("margin-block: "), i(1), t(";"),
  }),

  s("min", {
    t("margin-inline: "), i(1), t(";"),
  }),

  s("bf", {
    t({
      "&::before {",
      "\tcontent: '';",
      "\tposition: absolute;",
      "\ttop: 0;",
      "\tleft: 0;",
      "\tdisplay: block;",
      "\twidth: ",
    }),
    i(1),
    t({ ";", "\theight: " }),
    rep(1),
    t({ ";", "}" }),
  }),

  s("af", {
    t({
      "&::after {",
      "\tcontent: '';",
      "\tposition: absolute;",
      "\ttop: 0;",
      "\tleft: 0;",
      "\tdisplay: block;",
      "\twidth: ",
    }),
    i(1),
    t({ ";", "\theight: " }),
    rep(1),
    t({ ";", "}" }),
  }),
}

return {
  css = css_scss_snippets,
  scss = css_scss_snippets,
}
