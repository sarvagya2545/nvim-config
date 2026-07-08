return {
    "nvim-telescope/telescope.nvim",
    version = "*",
    event = "VeryLazy",
    dependencies = {
        "nvim-lua/plenary.nvim",
        { "nvim-telescope/telescope-fzf-native.nvim", build = "make" },
        { "nvim-tree/nvim-web-devicons", enabled = vim.g.have_nerd_font },
        "folke/todo-comments.nvim",
    },
    config = function()
        local telescope = require("telescope")
        local actions = require("telescope.actions")
        local theme = require("telescope.themes").get_ivy

        telescope.setup({
            defaults = theme({
                path_display = { "smart" },
                mappings = {
                    i = {
                        ["<C-k>"] = actions.move_selection_previous, -- move to prev result
                        ["<C-j>"] = actions.move_selection_next, -- move to next result
                        ["<C-q>"] = actions.send_selected_to_qflist + actions.open_qflist,
                    },
                },
            }),
            pickers = {
                find_files = {
                    find_command = { "rg", "--files", "--iglob", "!.git", "--hidden" },
                },
                git_branches = {
                    mappings = {
                        i = { ["<cr>"] = actions.git_switch_branch },
                    },
                },
            },
        })

        telescope.load_extension("fzf")

        local builtin = require("telescope.builtin")

        -- set keymaps
        local keymap = vim.keymap -- for conciseness

        keymap.set("n", "<leader>ff", builtin.find_files, { desc = "Fuzzy find files in cwd" })
        keymap.set("n", "<leader>fr", builtin.oldfiles, { desc = "Fuzzy find recent files" })
        keymap.set("n", "<leader>fs", builtin.live_grep, { desc = "Find string in cwd" })
        keymap.set("n", "<leader>fc", builtin.grep_string, { desc = "Find string under cursor in cwd" })
        keymap.set("n", "<leader>ft", "<cmd>TodoTelescope<cr>", { desc = "Find todos" })
        keymap.set("n", "<leader>tt", "<cmd>Telescope builtin<cr>", { desc = "Telescope builtin" })

        -- git branch keymaps
        keymap.set("n", "<leader>fb", function()
            builtin.git_branches({
                show_remote_tracking_branches = false,
            })
        end, { desc = "Git branch (local)" })

        keymap.set("n", "<leader>fB", function()
            builtin.git_branches({
                show_remote_tracking_branches = true,
            })
        end, { desc = "Git branch (remote included)" })
    end,
}
