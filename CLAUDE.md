# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

This is a LazyVim-based Neovim configuration optimized for web development (HTML/CSS/SCSS/JavaScript/TypeScript/Vue/PHP). It uses Lazy.nvim as the plugin manager and includes extensive custom configurations for web development workflows.

## Key Configuration Structure

- `init.lua` - Entry point that bootstraps lazy.nvim and loads core modules
- `lua/config/` - Core configuration files:
  - `lazy.lua` - Plugin manager setup with LazyVim extras (TypeScript, Vue)
  - `keymaps.lua` - Custom keybindings
  - `autocmds.lua` - Auto-commands and filetype-specific settings
  - `options.lua` - Vim options (autoformat is disabled by default)
  - `functions.lua` - Custom utility functions (BEM class helper, floating terminal)
  - `px-to-rem.lua` - CSS pixel to rem conversion tool
  - `tab-split.lua` - Tab/split management
  - `css-sort.lua` - CSS property sorting utilities
  - `snippet-blacklist.lua` - Snippet filtering logic
- `lua/plugins/` - Plugin configurations (each file configures specific plugins)
- `lua/snippets/` - Custom snippet definitions (html.lua, js.lua, scss.lua)

## Development Commands

### Testing Configuration Changes
```bash
# Reload configuration without restarting (excludes plugins)
# Use <leader>rr keymap in normal mode
```

### Formatting
```bash
# Format files using the configured formatters:
# - PHP/Blade: blade-formatter (or php-cs-fixer via <leader>fp)
# - JavaScript/TypeScript/Vue: prettier/prettierd
# - CSS/SCSS: prettier + stylelint
# - HTML: prettier/prettierd

# Alt+L in normal mode - format current file with view preservation
# <leader>ff - async LSP format
```

### Node Dependencies
```bash
npm install  # Install stylelint and related packages
```

### Formatter Paths
- Prettier: `~/.local/share/nvim/mason/bin/prettier`
- Stylelint: `~/.config/nvm/versions/node/v22.19.0/bin/stylelint`
- PHP CS Fixer: `~/.local/bin/php-cs-fixer`
- Blade Formatter: Uses global `blade-formatter` command

## Architecture Notes

### Plugin Management
- Uses LazyVim as base configuration with custom overrides
- Plugins are lazy-loaded by default (see `lua/config/lazy.lua`)
- Mason auto-installs: html-lsp, css-lsp, emmet-language-server, volar, intelephense, prettier, stylelint, phpcs, phpstan

### LSP Configuration
- **Vue**: Uses Volar in takeover mode (handles TS/JS for Vue projects)
- **PHP**: Intelephense with custom stubs for WordPress/WooCommerce/ACF Pro (stubs located in `stubs/`)
- **CSS/SCSS**: cssls with snippet support enabled
- **Emmet**: emmet-language-server (replaces deprecated emmet-ls)

### Completion System
- Uses blink.cmp with LuaSnip integration
- Custom snippet prioritization logic in `lua/plugins/completion-config.lua`
- Snippet blacklist system prevents snippet suggestions in certain contexts
- LSP items are filtered when custom snippets match exactly

### Formatting Pipeline
- Conform.nvim handles all formatting
- CSS/SCSS: prettier runs first, then stylelint fixes (sync mode to ensure proper ordering)
- Special spacing logic for SCSS/CSS closing braces (see keymaps.lua:53-75)
- View (cursor position and folds) is preserved during formatting

### Custom Utilities
- **PX to REM converter**: `<leader>pr` (converts pixels to rem units, ignores borders/letter-spacing/media queries)
- **BEM class helper**: `<leader>vs` (extracts base class and copies with `__` suffix to register `i`)
- **Floating terminal**: `Ctrl+;` (toggles persistent floating terminal)
- **CSS auto-spacing**: Automatically adds spacing between CSS/SCSS elements after format

### Filetype-Specific Settings
- Web files (JS/TS/Vue/HTML/CSS/SCSS/PHP): 2-space indentation
- Auto-save on focus lost
- Trailing whitespace removal on save
- Highlight on yank (200ms)

### Important Keybindings
- `Alt+L`: Fast format with view preservation
- `Ctrl+S`: Save without formatting, preserve folds
- `<leader>ff`: Format file (async)
- `<leader>pr`: Convert px to rem
- `<leader>vs`: Copy BEM class
- `Ctrl+;`: Toggle floating terminal
- `<leader>rr`: Reload config (keymaps, options, autocmds only)
- `jj`: Exit insert mode
- `Ctrl+j` (insert): Insert new line below and exit insert

## Config Reload Behavior

The `<leader>rr` keymap reloads ONLY configuration files (not plugins):
- Clears package cache for `config.*` and `snippets.*` modules
- Reloads options.lua, keymaps.lua, autocmds.lua
- Plugins are NOT reloaded (requires restart)

## Backup Strategy

Based on project instructions in existing CLAUDE.md:
- Backup location: `~/.config/nvim.ideal`
- Each backup overwrites the previous one in the same directory
