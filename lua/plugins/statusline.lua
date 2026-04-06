return {
    {
        "nvim-mini/mini.statusline",
        enabled = true,
        version = "*",
        dependencies = {
            "lewis6991/gitsigns.nvim",
            "nvim-tree/nvim-web-devicons",
        },
        config = function()
            -- when this plugin loads, i want to not show the mode
            vim.o.showmode = false
            local statusline = require("mini.statusline")

            local function get_branch()
                local branch = vim.b.gitsigns_head
                if branch and branch ~= "" then
                    -- return "⎇ " .. branch
                    return " " .. branch
                end
                return ""
            end

            local function get_diff()
                local dict = vim.b.gitsigns_status_dict
                if not dict then return "" end

                local added   = dict.added and dict.added > 0 and ("%#MiniStatuslineAdded#+") .. dict.added or ""
                local changed = dict.changed and dict.changed > 0 and ("%#MiniStatuslineChanged#~") .. dict.changed or ""
                local removed = dict.removed and dict.removed > 0 and ("%#MiniStatuslineRemoved#-") .. dict.removed or ""

                return table.concat({ added, changed, removed }, " "):gsub("^%s+", "")
            end

            statusline.setup({
                content = {
                    active = function()
                        local mode, mode_hl = statusline.section_mode({ trunc_width = 120 })

                        -- git branch
                        -- local branch = vim.fn.system("git branch --show-current 2>/dev/null"):gsub("%s+", "")
                        local git = get_branch()

                        -- filename + modified flag
                        local filename = vim.fn.expand("%:t") -- just the filename, no path
                        local modified = vim.bo.modified and " ●" or ""
                        local file = filename ~= "" and (filename .. modified) or "[No Name]"

                        -- diagnostics
                        local diag = statusline.section_diagnostics({ trunc_width = 75 })

                        -- right side
                        local encoding = vim.bo.fileencoding ~= "" and vim.bo.fileencoding or vim.o.encoding
                        local location = "%l:%c"
                        local filetype = vim.bo.filetype

                        return statusline.combine_groups({
                            { hl = mode_hl,                    strings = { mode } },
                            { hl = "MiniStatuslineBranch",     strings = { git } },
                            { hl = "MiniStatuslineFilename",   strings = { file } },
                            { hl = "MiniStatuslineFilename",   strings = { get_diff() } },
                            { hl = "MiniStatuslineDiagnostic", strings = { diag } },
                            "%=", -- right align everything after this
                            { hl = "MiniStatuslineEncoding", strings = { encoding } },
                            { hl = "MiniStatuslineFileinfo", strings = { filetype } },
                            { hl = mode_hl,                  strings = { location } },
                        })
                    end,
                },
            })

            local colors = {
                blue        = "#65D1FF",
                green       = "#3EFFDC",
                violet      = "#FF61EF",
                yellow      = "#FFDA7B",
                red         = "#FF4A4A",
                fg          = "#c3ccdc",
                bg          = "#112638",
                inactive_bg = "#2c3043",
            }

            local hl = vim.api.nvim_set_hl

            -- Mode highlight groups
            hl(0, "MiniStatuslineModeNormal", { fg = colors.bg, bg = colors.blue, bold = true })
            hl(0, "MiniStatuslineModeInsert", { fg = colors.bg, bg = colors.green, bold = true })
            hl(0, "MiniStatuslineModeVisual", { fg = colors.bg, bg = colors.violet, bold = true })
            hl(0, "MiniStatuslineModeCommand", { fg = colors.bg, bg = colors.yellow, bold = true })
            hl(0, "MiniStatuslineModeReplace", { fg = colors.bg, bg = colors.red, bold = true })

            -- Left side highlight groups
            hl(0, "MiniStatuslineFilename", { fg = colors.fg, bg = colors.bg })
            hl(0, "MiniStatuslineBranch", { fg = colors.fg, bg = colors.bg })
            hl(0, "MiniStatuslineDiagnostic", { fg = colors.fg, bg = colors.bg })

            -- Git diff highlight groups
            hl(0, "MiniStatuslineAdded", { fg = colors.green, bg = colors.bg })
            hl(0, "MiniStatuslineChanged", { fg = colors.yellow, bg = colors.bg })
            hl(0, "MiniStatuslineRemoved", { fg = colors.red, bg = colors.bg })

            -- Right side highlight groups
            hl(0, "MiniStatuslineEncoding", { fg = colors.fg, bg = colors.bg })
            hl(0, "MiniStatuslineFileinfo", { fg = colors.fg, bg = colors.inactive_bg })
            hl(0, "MiniStatuslineInactive", { fg = colors.fg, bg = colors.inactive_bg })

            vim.api.nvim_create_autocmd("User", {
                pattern = "GitSignsUpdate",
                callback = function()
                    vim.cmd("redrawstatus")
                end,
            })

            vim.api.nvim_create_autocmd({
                'WinEnter',
                'BufEnter',
                'BufWritePost',
                'SessionLoadPost',
                'FileChangedShellPost',
                'VimResized',
                'CursorMoved',
                'CursorMovedI',
                'ModeChanged',
            }, {
                callback = function()
                    vim.cmd("redrawstatus")
                end,
            })
        end
    },
}
