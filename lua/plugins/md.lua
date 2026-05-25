return {
    {
        "delphinus/md-render.nvim",
        enabled = false,
        version = "*",
        dependencies = {
            { "nvim-tree/nvim-web-devicons", version = "*" }, -- optional: file type icons in code blocks
            { "delphinus/budoux.lua", version = "*" }, -- optional: CJK phrase-level line breaking
        },
        keys = {
            { "<leader>mp", "<Plug>(md-render-preview)", desc = "Markdown preview (toggle)" },
            { "<leader>mt", "<Plug>(md-render-preview-tab)", desc = "Markdown preview in tab (toggle)" },
            { "<leader>md", "<Plug>(md-render-demo)", desc = "Markdown render demo" },
        },
    },
    {
        "MeanderingProgrammer/render-markdown.nvim",
        -- dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-mini/mini.nvim" }, -- if you use the mini.nvim suite
        -- dependencies = { 'nvim-treesitter/nvim-treesitter', 'nvim-mini/mini.icons' },        -- if you use standalone mini plugins
        dependencies = { "nvim-treesitter/nvim-treesitter", "nvim-tree/nvim-web-devicons" }, -- if you prefer nvim-web-devicons
        ---@module 'render-markdown'
        ---@type render.md.UserConfig
        opts = {},
    },
    {
        "iamcco/markdown-preview.nvim",
        cmd = { "MarkdownPreviewToggle", "MarkdownPreview", "MarkdownPreviewStop" },
        build = "cd app && npm install",
        init = function()
            vim.g.mkdp_filetypes = { "markdown" }
        end,
        ft = { "markdown" },
    },
}
