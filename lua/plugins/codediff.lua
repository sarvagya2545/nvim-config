local codediff_is_open = false

vim.api.nvim_create_autocmd("User", {
    pattern = "CodeDiffOpen",
    callback = function()
        codediff_is_open = true
    end,
})

vim.api.nvim_create_autocmd("User", {
    pattern = "CodeDiffClose",
    callback = function()
        codediff_is_open = false
    end,
})

local function toggle_codediff(cmd)
    if not codediff_is_open then
        vim.cmd(cmd)
    else
        vim.cmd("tabclose") -- CodeDiff opens in its own tab; closing it fires CodeDiffClose
    end
end

return {
    {
        "esmuellert/codediff.nvim",
        cmd = "CodeDiff",
        keys = {
            {
                "<leader>gd",
                function()
                    toggle_codediff("CodeDiff")
                end,
                desc = "Diff Index",
            },
            {
                "<leader>gD",
                function()
                    toggle_codediff("CodeDiff main HEAD")
                end,
                desc = "Diff master",
            },
            {
                "<leader>gf",
                function()
                    toggle_codediff("CodeDiff history %")
                end,
                desc = "Open diffs for current File",
            },
        },
        opts = {
            highlights = {
                line_insert = "DiffAdd",
                line_delete = "DiffDelete",
            },
        },
    },
}
