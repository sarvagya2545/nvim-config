-- Refocus the terminal after inverse search
-- Replace "TERMINAL" with your terminal app name, e.g. "iTerm", "Alacritty", "kitty", "WezTerm"
local function tex_focus_vim()
    vim.cmd("silent !open -a WezTerm")
    vim.cmd("redraw!")
end

vim.api.nvim_create_autocmd("User", {
    pattern = "VimtexEventViewReverse",
    group = vim.api.nvim_create_augroup("vimtex_event_focus", { clear = true }),
    callback = tex_focus_vim,
})

-- Close the Skim window for this PDF when quitting vimtex
local function close_viewer()
    local out = vim.fn.expand("%:r") .. ".pdf"
    local pdf_name = vim.fn.fnamemodify(out, ":t")
    vim.fn.system(
        'osascript -e \'tell application "Skim" to close ' .. '(every document whose name is "' .. pdf_name .. "\")'"
    )
end

vim.api.nvim_create_autocmd("User", {
    pattern = { "VimtexEventQuit", "VimtexEventCompileStopped" },
    group = vim.api.nvim_create_augroup("vimtex_event_close", { clear = true }),
    callback = close_viewer,
})
