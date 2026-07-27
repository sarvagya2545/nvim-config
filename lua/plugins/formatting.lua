return {
    "stevearc/conform.nvim",
    event = { "BufReadPre", "BufNewFile" },
    config = function()
        local conform = require("conform")

        -- variable to specify autoformat on global level
        vim.g.format_on_save = true

        -- if during contest, then do not format on save unless it is enabled
        if vim.env.NVIM_CONTEST_MODE then
            vim.g.format_on_save = false
        end

        conform.setup({
            formatters_by_ft = {
                javascript = { "prettier" },
                typescript = { "prettier" },
                javascriptreact = { "prettier" },
                typescriptreact = { "prettier" },
                css = { "prettier" },
                html = { "prettier" },
                json = { "prettier" },
                yaml = { "prettier" },
                markdown = { "mdformat" },
                lua = { "stylua" },
                python = { "isort", "black" },
            },
            format_on_save = function(bufnr)
                if vim.g.format_on_save and vim.b[bufnr].autoformat ~= false then
                    return {
                        lsp_fallback = true,
                        async = false,
                        timeout_ms = 1000,
                    }
                end
            end,
        })

        vim.keymap.set({ "n", "v" }, "<leader>mp", function()
            conform.format({
                lsp_fallback = true,
                async = false,
                timeout_ms = 1000,
            })
        end, { desc = "Format file or range (in visual mode)" })

        vim.api.nvim_create_user_command("FormatToggle", function()
            vim.g.format_on_save = not vim.g.format_on_save
            print("Autoformat: " .. (vim.g.format_on_save and "ON" or "OFF"))
        end, {
            desc = "Toggle Autoformat globally",
        })
    end,
}
