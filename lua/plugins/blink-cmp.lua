-- ~/.config/nvim/lua/plugins/blink.lua
-- blink.cmp — stable v1 configuration for lazy.nvim
-- Docs: https://cmp.saghen.dev

local function testfunc() end
testfunc()

return {
    "saghen/blink.cmp",

    -- Pin to the stable v1 line. This downloads a prebuilt Rust fuzzy-matcher
    -- binary that matches the tagged release, so you don't need cargo installed.
    version = "1.*",

    -- Optional but recommended dependencies:
    dependencies = {
        "rafamadriz/friendly-snippets", -- community snippets for the `snippets` source
        -- 'L3MON4D3/LuaSnip',          -- uncomment if you want LuaSnip instead of vim.snippet
    },

    -- Load on insert/cmdline so startup stays fast (lazy.nvim handles this).
    event = { "InsertEnter", "CmdlineEnter" },

    --- @module 'blink.cmp'
    --- @type blink.cmp.Config
    opts = {
        -- ── Keymap ────────────────────────────────────────────────────────────
        -- Presets: 'default' (C-y to accept), 'super-tab', 'enter', 'none'.
        keymap = {
            preset = "default",
            ["<C-k>"] = { "select_prev", "fallback" },
            ["<C-j>"] = { "select_next", "fallback" },
            ["<C-u>"] = { "scroll_documentation_up", "fallback" },
            ["<C-d>"] = { "scroll_documentation_down", "fallback" },
            -- Override individual keys if you like:
            -- ['<C-space>'] = { 'show', 'show_documentation', 'hide_documentation' },
            -- ["<CR>"] = { "accept", "fallback" },
        },

        -- ── Appearance ────────────────────────────────────────────────────────
        appearance = {
            -- 'mono' for 'Nerd Font Mono', 'normal' for 'Nerd Font'
            nerd_font_variant = "mono",
            -- Fall back to nvim-cmp highlight groups when your theme lacks blink ones
            use_nvim_cmp_as_default = false,
        },

        -- ── Completion behaviour ──────────────────────────────────────────────
        completion = {
            -- Resolve and apply additional text edits (e.g. auto-imports) on accept
            accept = {
                auto_brackets = { enabled = true }, -- add () after functions
            },

            menu = {
                border = "none",
                draw = {
                    -- Treesitter-highlight the label text for these sources
                    treesitter = { "lsp" },
                    -- Columns shown in the menu
                    columns = {
                        { "kind_icon" },
                        { "label", "label_description", gap = 1 },
                        { "source_name" }, -- shows [LSP] / [Buffer] / [Path] etc.
                    },
                },
            },

            documentation = {
                auto_show = true,
                auto_show_delay_ms = 200,
                window = { border = "rounded" },
            },

            -- Inline virtual-text preview of the selected item
            ghost_text = { enabled = false },

            list = {
                selection = {
                    auto_insert = false,
                },
            },
        },

        -- ── Signature help (function arg hints) ───────────────────────────────
        signature = {
            enabled = true,
            window = { border = "rounded" },
        },

        -- ── Snippets ──────────────────────────────────────────────────────────
        -- Presets: 'default' (uses Neovim's built-in vim.snippet), 'luasnip',
        -- 'mini_snippets', 'vsnip'. friendly-snippets is auto-loaded for 'default'.
        snippets = { preset = "default" },

        -- ── Sources ───────────────────────────────────────────────────────────
        -- The four below are built in and enabled by default. Order matters only
        -- as a tiebreaker; final ranking is by fuzzy score + score_offset.
        sources = {
            default = { "lsp", "path", "snippets", "buffer" },

            -- Per-filetype source overrides (optional):
            per_filetype = {
                sql = {},
                mysql = {},
            },

            -- Per-source tuning lives here. See the "adding sources" notes below.
            providers = {
                -- Example: nudge buffer completions lower so LSP wins ties
                buffer = { score_offset = -3 },
            },
        },

        -- ── Fuzzy matcher ─────────────────────────────────────────────────────
        -- 'prefer_rust_with_warning' (default): use the Rust binary, warn + fall
        -- back to Lua if it's missing. Use 'lua' to avoid the binary entirely.
        fuzzy = { implementation = "prefer_rust_with_warning" },

        -- Command line keybinds ------------------------------------------------
        cmdline = {
            enabled = true,
            keymap = {
                preset = "cmdline",
                ["<C-k>"] = { "select_prev", "fallback" },
                ["<C-j>"] = { "select_next", "fallback" },
            },

            completion = {
                list = {
                    selection = {
                        auto_insert = true,
                    },
                },
            },
        },
    },

    -- Lets the type annotations above merge cleanly if other specs extend opts
    opts_extend = { "sources.default" },
}
