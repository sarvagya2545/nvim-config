return {
    {
        "https://github.com/lervag/vimtex",
        init = function()
            vim.g.vimtex_view_method = "skim"
            vim.g.vimtex_quickfix_open_on_warning = false
            vim.g.vimtex_compiler_latexmk = {
                out_dir = "build",
                callback = 1,
                continuous = 1,
                executable = "latexmk",
                options = {
                    "-verbose",
                    "-file-line-error",
                    "-synctex=1",
                    "-interaction=nonstopmode",
                },
            }
        end,
    },
}
