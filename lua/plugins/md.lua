return {
    {
        "https://github.com/bullets-vim/bullets.vim",
        config = function()
            vim.g.bullets_outline_levels = { "num" }
            vim.g.bullets_renumber_on_change = 0
        end,
    }, -- for auto bullet points and lists
    {
        "MeanderingProgrammer/render-markdown.nvim",
        -- dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" }, -- if you use the mini.nvim suite
        -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },        -- if you use standalone mini plugins
        dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
        ---@module 'render-markdown'
        ---@type render.md.UserConfig
        opts = {
            code = {
                render_modes = true,
            },
            heading = {
                render_modes = true,
            },
            links = {
                render_modes = true,
            },
        },
    },
    {
        "iamcco/markdown-preview.nvim",
        cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
        build = "cd app && npm install && git restore .",
        init = function()
            vim.g.mkdp_filetypes = { "markdown" }
            vim.g.mkdp_port = "9090"
            vim.g.mkdp_echo_preview_url = 1
            vim.g.mkdp_theme = "light"
        end,
        ft = { "markdown" },
        keys = {
            { "<leader>mP", "<cmd>MarkdownPreviewToggle<CR>", desc = "Markdown preview (web)" },
        },
    },
}
