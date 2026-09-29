-- Neovim: Catppuccin Mocha on a transparent background, so Ghostty's 85% blur
-- shows through like it does in btop and the shell. The font comes from Ghostty
-- (JetBrainsMono Nerd Font), which also draws the statusline icons.
-- Plugins are managed by lazy.nvim, fetched from GitHub on the first start.

vim.g.mapleader = " "

-- ───────── Look ─────────
vim.opt.termguicolors = true
vim.opt.number = true
vim.opt.cursorline = true
vim.opt.signcolumn = "yes"
vim.opt.showmode = false          -- the statusline shows the mode
vim.opt.laststatus = 3            -- one statusline for all splits
vim.opt.fillchars = { eob = " " } -- no ~ below the end of the file
vim.opt.mouse = "a"

-- ───────── Plugins ─────────
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.uv.fs_stat(lazypath) then
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable",
    "https://github.com/folke/lazy.nvim.git", lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({ { "Couldn't download lazy.nvim (offline?):\n", "ErrorMsg" }, { out } }, true, {})
    return
  end
end
vim.opt.rtp:prepend(lazypath)

require("lazy").setup({
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      flavour = "mocha",
      transparent_background = true,
      float = { transparent = true },
    },
    config = function(_, opts)
      require("catppuccin").setup(opts)
      vim.cmd.colorscheme("catppuccin")
    end,
  },
  {
    -- Rounded, pill-shaped sections like the SketchyBar pills
    "nvim-lualine/lualine.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      options = {
        theme = "catppuccin-mocha",
        section_separators = { left = "\u{e0b4}", right = "\u{e0b6}" }, -- Nerd Font half circles
        component_separators = "",
        globalstatus = true,
      },
      sections = {
        lualine_a = { { "mode", separator = { left = "\u{e0b6}" } } },
        lualine_z = { { "location", separator = { right = "\u{e0b4}" } } },
      },
    },
  },
}, {
  install = { colorscheme = { "catppuccin" } },
  change_detection = { notify = false },
  ui = { border = "rounded" },
})
