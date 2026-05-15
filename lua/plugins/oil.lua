return {
    {
        "https://github.com/stevearc/oil.nvim",
        enabled = true,
        opts = {},
        config = function()
            require("oil").setup({
                keymaps = {
                    ["<C-h>"] = false,
                    ["<C-l>"] = false,
                },
                view_options = {
                    show_hidden = true,
                },
            })

            vim.keymap.set("n", "-", "<CMD>Oil<CR>", { desc = "Open parent directory" })
            vim.keymap.set("n", "<leader>-", require("oil").toggle_float, { desc = "Open Oil in floating window" })
        end,
    },
}
