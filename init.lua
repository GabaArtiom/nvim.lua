-- bootstrap lazy.nvim, LazyVim and your plugins
require("config.lazy")

-- Load custom functions
require("config.functions").setup()

-- Load tab-split functionality
require("config.tab-split")
