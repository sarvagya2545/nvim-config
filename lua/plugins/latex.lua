return {
    {
        "https://github.com/lervag/vimtex",
        init = function()
            vim.g.vimtex_view_method = "skim"
            vim.g.vimtex_quickfix_open_on_warning = false
        end,
    },
}
