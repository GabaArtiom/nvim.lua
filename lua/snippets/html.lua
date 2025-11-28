local ls = require("luasnip")
local rep = require("luasnip.extras").rep
local s = ls.snippet
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node

-- Общие сниппеты (и для html, и для php)
local shared_snippets = {

  s("ctr", {
    t('<div class="container">'),
    i(1),
    t("</div>"),
  }),

  s("tb", {
    t('target="_blank"'),
  }),

  s("cl", {
    t('class="'),
    i(1),
    t('"'),
  }),

  s("a", {
    t('<a class="'),
    f(function()
      local reg = vim.fn.getreg("i") or ""
      local base = reg:match("^(.-__)") or reg
      return base
    end, {}),
    i(1), -- продолжение класса после __
    t('" href="'),
    i(2, "https://"),
    t('" target="_blank">'),
    i(3), -- контент ссылки
    t("</a>"),
  }),

  s("btn", {
    t('<button class="'),
    f(function()
      local reg = vim.fn.getreg("i") or ""
      local base = reg:match("^(.-__)") or reg
      return base
    end, {}),
    i(1), -- продолжение класса после __
    t('" type="'),
    i(2, "button"),
    t('">'),
    i(3), -- контент кнопки
    t("</button>"),
  }),

  -- div with class from register i (BEM)
  s("dv", {
    f(function()
      local reg = vim.fn.getreg("i") or ""
      local base = reg:match("^(.-__)") or reg
      return '<div class="' .. base
    end, {}),
    i(1), -- ввод элемента
    t('">'),
    i(2), -- содержимое
    t("</div>"),
  }),

  s("dvv", {
    t("<"),
    i(1, "div"),
    t(' class="'),
    f(function()
      local reg = vim.fn.getreg("i") or ""
      local base = reg:match("^(.-__)") or reg
      return base
    end, {}),
    i(2),
    t('">'),
    i(3),
    t('</'),
    rep(1),
    t(">"),
  }),

  s("iv", {
    t("<"),
    i(1, "div"),
    t(' class="'),
    f(function()
      local reg = vim.fn.getreg("i") or ""
      local base = reg:match("^(.-__)") or reg
      return base
    end, {}),
    i(2),
    t('"><?php echo $'),
    rep(2),
    t('; ?>'),
    i(3),
    t('</'),
    rep(1),
    t(">"),
  }),

  s("cp", {
    t("<?php create_picture(my_get_image_id($"),
    i(1),
    t(")) ?>"),
  }),

  s("d", {
    t("<"),
    i(1, "div"), -- тег (по умолчанию div)
    t(' class="'),
    f(function()
      local reg = vim.fn.getreg("i") or ""
      local base = reg:match("^(.-__)") or reg
      return base
    end, {}),
    i(2),   -- дополнительный класс
    t('">'),
    i(3),   -- содержимое
    t("</"),
    rep(1), -- повтор тега
    t(">"),
  }),

  s("di", {
    t("<"),
    i(1, "div"), -- тег (по умолчанию div)
    t(' class="'),
    f(function()
      local reg = vim.fn.getreg("i") or ""
      local base = reg:match("^(.-__)") or reg
      return base
    end, {}),
    i(2),   -- элемент
    t('">'),
    i(3),   -- содержимое
    t("</"),
    rep(1), -- повтор тега
    t(">"),
  }),

  s("im", {
    t('<img src="<?php echo $'),
    i(1), -- переменная
    t("['url']; ?>\" alt=\"<?php echo $"),
    rep(1),
    t("['alt']; ?>\" />"),
  }),

  s("imm", {
    t('<img src="<?php echo $'),
    i(1), -- например: image
    t("['url']; ?>\" class=\""),
    f(function()
      local reg = vim.fn.getreg("i") or ""
      local base = reg:match("^(.-__)") or reg
      return base
    end, {}),
    i(2),
    t('" alt="<?php echo '),
    rep(1),
    t("['alt']; ?>\" />"),
  }),

  s("atel", {
    t('<a href="tel:<?php echo clear_phone($'),
    i(1),
    t('); ?>" target="_blank"><?php echo $'),
    rep(1),
    t("; ?></a>"),
  }),

  s("amail", {
    t('<a href="mailto:<?php echo $'),
    i(1),
    t('; ?>" target="_blank"><?php echo $'),
    rep(1),
    t("; ?></a>"),
  }),

  s("php", {
    t("<?php "),
    i(1),
    t(" ?>"),
  }),

  s("pv", {
    t("<?php echo $"),
    i(1),
    t("; ?>"),
  }),

  s("frc", {
    t("<?php foreach($"),
    i(1),
    t(" as $"),
    i(2),
    t({ "): ?>", "\t" }),
    i(3),
    t({ "", "<?php endforeach; ?>" }),
  }),

  s("gf", {
    t("get_field( '"),
    i(1),
    t("' );"),
  }),

  s("gft", {
    t("get_field( '"),
    i(1),
    t("', 'options' );"),
  }),

  s("if", {
    t({ "<?php if(" }),
    i(1),
    t({ "): ?>", "\t" }),
    i(2),
    t({ "", "<?php else: ?>", "\t" }),
    i(3),
    t({ "", "<?php endif; ?>" }),
  }),

  s("gtp", {
    t("<?php get_template_part( 'template-parts/"),
    i(1),
    t("' ); ?>"),
  }),

  s("vd", {
    t("var_dump("),
    i(1),
    t(");"),
  }),

  s("mgi", {
    t("$"),
    i(1),
    t(" = my_get_image_id($"),
    i(2),
    t("['"),
    rep(1), -- повторяет первый insert node
    t("']);"),
  }),
}

return {
  html = shared_snippets,
  php = shared_snippets,
  vue = shared_snippets,
}
