return {
    "williamboman/mason.nvim",
    event = "VeryLazy",
    dependencies = {
        "WhoIsSethDaniel/mason-tool-installer.nvim",
    },
    config = function()
        -- import mason
        local mason = require("mason")
        local mason_tool_installer = require("mason-tool-installer")

        -- enable mason and configure icons
        mason.setup({
            ui = {
                icons = {
                    package_installed = "✓",
                    package_pending = "➜",
                    package_uninstalled = "✗",
                },
            },
        })

        -- List of tools to install
        local lsp_servers = {
            "lua-language-server",
            "clangd",
            "ruff",
            "ty",
            "typescript-language-server",
            "groovy-language-server",
            "json-lsp",
            "bash-language-server",
        }
        local formatters = { "prettier", "stylua", "clang-format" }
        local linters = { "eslint_d" }
        local debuggers = { "debugpy" }

        if vim.fn.executable("go") == 1 then
            table.insert(debuggers, "delve")
            table.insert(lsp_servers, "gopls")
        end

        -- merge the tools to be installed into single list
        local ensure_installed = {}
        vim.list_extend(ensure_installed, formatters)
        vim.list_extend(ensure_installed, linters)
        vim.list_extend(ensure_installed, debuggers)
        vim.list_extend(ensure_installed, lsp_servers)

        -- Mason tool installer
        mason_tool_installer.setup({ ensure_installed = ensure_installed })
    end,
}
