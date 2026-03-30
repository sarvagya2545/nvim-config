return {
    {
        "nvim-mini/mini.statusline",
        enabled = false,
        version = "*",
        dependencies = {
            "lewis6991/gitsigns.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            -- when this plugin loads, i want to not show the mode
            vim.o.showmode = false
            local statusline = require("mini.statusline")
            local colors = {
                blue = "#65D1FF",
                green = "#3EFFDC",
                violet = "#FF61EF",
                yellow = "#FFDA7B",
                red = "#FF4A4A",
                fg = "#c3ccdc",
                bg = "#112638",
                inactive_bg = "#2c3043",
            }

            local function hi(group, fg, bg, bold)
                vim.api.nvim_set_hl(0, group, {
                    fg = fg,
                    bg = bg,
                    bold = bold or false,
                })
            end

            -- Normal mode
            hi("MiniStatuslineModeNormal", colors.bg, colors.blue, true)

            -- Insert mode
            hi("MiniStatuslineModeInsert", colors.bg, colors.green, true)

            -- Visual mode
            hi("MiniStatuslineModeVisual", colors.bg, colors.violet, true)

            -- Command mode
            hi("MiniStatuslineModeCommand", colors.bg, colors.yellow, true)

            -- Replace mode
            hi("MiniStatuslineModeReplace", colors.bg, colors.red, true)

            -- Inactive
            hi("MiniStatuslineInactive", colors.fg, colors.inactive_bg)

            -- Default sections
            hi("MiniStatuslineDevinfo", colors.fg, colors.bg)
            hi("MiniStatuslineFilename", colors.fg, colors.bg)
            hi("MiniStatuslineFileinfo", colors.fg, colors.bg)

            statusline.setup({
                use_icons = true,
            })

            vim.api.nvim_create_autocmd({ "ModeChanged", "CursorMoved", "CursorMovedI" }, {
                callback = function()
                    vim.cmd("redrawstatus")
                end,
            })
        end,
    },
}
