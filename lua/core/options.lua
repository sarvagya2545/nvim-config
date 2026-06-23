vim.cmd("let g:netrw_liststyle = 3")

local opt = vim.opt

-- line numbering
opt.relativenumber = true
opt.number = true

-- tabs and indentation
opt.tabstop = 4
opt.shiftwidth = 4
opt.expandtab = true
opt.autoindent = true

-- search settings
opt.ignorecase = true -- ignore case when searching
opt.smartcase = true -- if you include mixed case in your search, assumes you want

opt.cursorline = false

-- turn on termguicolors for nightfly colorscheme to work
-- (have to use iterm2 or any other true color terminal)
opt.termguicolors = true
opt.background = "dark" -- colorschemes that can be light or dark will be made dark
opt.signcolumn = "yes" -- show sign column so that text doesn't shift

-- backspace
opt.backspace = "indent,eol,start" -- allow backspace on indent, end of line or insert mode start position

-- clipboard
opt.clipboard:append("unnamedplus") -- use system clipboard as default register
vim.g.clipboard = {
    name = "OSC 52",
    copy = {
        ["+"] = require("vim.ui.clipboard.osc52").copy("+"),
        ["*"] = require("vim.ui.clipboard.osc52").copy("*"),
    },
    paste = {
        -- Return the last yank instead of querying WezTerm (which never answers).
        -- Avoids the 10s freeze; p still pastes nvim-internal yanks correctly.
        ["+"] = function()
            return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
        end,
        ["*"] = function()
            return { vim.fn.split(vim.fn.getreg(""), "\n"), vim.fn.getregtype("") }
        end,
    },
}

-- split windows
opt.splitright = true -- split vertical window to the right
opt.splitbelow = true -- split horizontal window to the bottom

opt.winborder = "bold"

-- related to project specific configurations
opt.exrc = true
opt.secure = true

-- disable swapfile
opt.swapfile = false
