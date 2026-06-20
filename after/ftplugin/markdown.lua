-- NOTE: go to the bottom of the file to toggle on or off certain features
-- features list:
-- - markdown folds
-- - todo lists
-- - jump between headers

local function markdown_folds()
    -- Checks each line to see if it matches a markdown heading (#, ##, etc.):
    -- It’s called implicitly by Neovim’s folding engine by vim.opt_local.foldexpr
    function _G.markdown_foldexpr()
        local lnum = vim.v.lnum
        local line = vim.fn.getline(lnum)
        local heading = line:match("^(#+)%s")
        -- print(lnum, line, heading)
        if heading then
            local level = #heading
            return ">" .. level
        end
        return "="
    end

    local function set_markdown_folding()
        vim.opt_local.foldmethod = "expr"
        vim.opt_local.foldexpr = "v:lua.markdown_foldexpr()"
        vim.opt_local.foldlevel = 99
        -- Keep folded headings rendered as the real heading line so EOL codelens stays visible.
        vim.opt_local.foldtext = ""

        -- Detect frontmatter closing line
        local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local found_first = false
        local frontmatter_end = nil
        for i, line in ipairs(lines) do
            if line == "---" then
                if not found_first then
                    found_first = true
                else
                    frontmatter_end = i
                    break
                end
            end
        end
        vim.b.frontmatter_end = frontmatter_end
    end
    set_markdown_folding()

    -- Function to fold all headings of a specific level
    local function fold_headings_of_level(level)
        -- Move to the top of the file without adding to jumplist
        vim.cmd("keepjumps normal! gg")
        -- Get the total number of lines
        local total_lines = vim.fn.line("$")
        for line = 1, total_lines do
            -- Get the content of the current line
            local line_content = vim.fn.getline(line)
            -- "^" -> Ensures the match is at the start of the line
            -- string.rep("#", level) -> Creates a string with 'level' number of "#" characters
            -- "%s" -> Matches any whitespace character after the "#" characters
            -- So this will match `## `, `### `, `#### ` for example, which are markdown headings
            if line_content:match("^" .. string.rep("#", level) .. "%s") then
                -- Move the cursor to the current line without adding to jumplist
                vim.cmd(string.format("keepjumps call cursor(%d, 1)", line))
                -- Check if the current line has a fold level > 0
                local current_foldlevel = vim.fn.foldlevel(line)
                if current_foldlevel > 0 then
                    -- Fold the heading if it matches the level
                    if vim.fn.foldclosed(line) == -1 then
                        vim.cmd("normal! za")
                    end
                end
            end
        end
    end

    local function fold_markdown_headings(levels)
        -- I save the view to know where to jump back after folding
        local saved_view = vim.fn.winsaveview()
        for _, level in ipairs(levels) do
            fold_headings_of_level(level)
        end
        vim.cmd("nohlsearch")
        -- Restore the view to jump to where I was
        vim.fn.winrestview(saved_view)
    end

    -- NOTE: Fold markdown headings in Neovim with a keymap
    -- https://youtu.be/EYczZLNEnIY

    -- Keymap for folding markdown headings of level 1 or above
    vim.keymap.set("n", "zj", function()
        -- Unfold everything first or I had issues
        vim.cmd("normal! zR")
        fold_markdown_headings({ 6, 5, 4, 3, 2, 1 })
        vim.cmd("normal! zz") -- center the cursor line on screen
    end, { desc = "[P]Fold all headings level 1 or above" })

    -- Keymap for folding markdown headings of level 2 or above
    -- I know, it reads like "madafaka" but "k" for me means "2"
    vim.keymap.set("n", "zk", function()
        -- Unfold everything first or I had issues
        vim.cmd("normal! zR")
        fold_markdown_headings({ 6, 5, 4, 3, 2 })
        vim.cmd("normal! zz") -- center the cursor line on screen
    end, { desc = "[P]Fold all headings level 2 or above" })

    -- Keymap for folding markdown headings of level 3 or above
    vim.keymap.set("n", "zl", function()
        -- Unfold everything first or I had issues
        vim.cmd("normal! zR")
        fold_markdown_headings({ 6, 5, 4, 3 })
        vim.cmd("normal! zz") -- center the cursor line on screen
    end, { desc = "[P]Fold all headings level 3 or above" })

    -- Keymap for folding markdown headings of level 4 or above
    vim.keymap.set("n", "z;", function()
        -- Unfold everything first or I had issues
        vim.cmd("normal! zR")
        fold_markdown_headings({ 6, 5, 4 })
        vim.cmd("normal! zz") -- center the cursor line on screen
    end, { desc = "[P]Fold all headings level 4 or above" })

    -- -- Use <CR> to fold when in normal mode
    -- -- To see help about folds use `:help fold`
    -- vim.keymap.set("n", "<CR>", function()
    --     -- Get the current line number
    --     local line = vim.fn.line(".")
    --     -- Get the fold level of the current line
    --     local foldlevel = vim.fn.foldlevel(line)
    --     if foldlevel == 0 then
    --         vim.notify("No fold found", vim.log.levels.INFO)
    --     else
    --         vim.cmd("normal! za")
    --         vim.cmd("normal! zz") -- center the cursor line on screen
    --     end
    -- end, { desc = "[P]Toggle fold" })

    -- Keymap for unfolding markdown headings of level 2 or above
    -- Changed all the markdown folding and unfolding keymaps from <leader>mfj to
    -- zj, zk, zl, z; and zu respectively lamw25wmal
    vim.keymap.set("n", "zu", function()
        vim.cmd("normal! zR") -- Unfold all headings
        vim.cmd("normal! zz") -- center the cursor line on screen
    end, { desc = "[P]Unfold all headings level 2 or above" })

    -- gk jumps to the markdown heading above and then folds it
    -- zi by default toggles folding, but I don't need it lamw25wmal
    vim.keymap.set("n", "zi", function()
        -- "Update" saves only if the buffer has been modified since the last save
        vim.cmd("silent update")
        -- Difference between normal and normal!
        -- - `normal` executes the command and respects any mappings that might be defined.
        -- - `normal!` executes the command in a "raw" mode, ignoring any mappings.
        vim.cmd("normal gk")
        -- This is to fold the line under the cursor
        vim.cmd("normal! za")
        vim.cmd("normal! zz") -- center the cursor line on screen
    end, { desc = "[P]Fold the heading cursor currently on" })
end

local function todo_items()
    vim.keymap.set({ "n", "i" }, "<M-x>", function()
        require("modules.markdown_tasks").toggle_done()
    end, { desc = "Toggle task and move it to 'done'" })

    -- Create task or checkbox lamw26wmal
    -- These are marked with <leader>x using bullets.vim
    -- I used <C-l> before, but that is used for pane navigation
    vim.keymap.set({ "n", "i" }, "<M-t>", function()
        -- Get the current line/row/column
        local cursor_pos = vim.api.nvim_win_get_cursor(0)
        local row, _ = cursor_pos[1], cursor_pos[2]
        local line = vim.api.nvim_get_current_line()
        -- 1) If line is empty => replace it with "- [ ] " and set cursor after the brackets
        if line:match("^%s*$") then
            local final_line = "- [ ] "
            vim.api.nvim_set_current_line(final_line)
            -- "- [ ] " is 6 characters, so cursor col = 6 places you *after* that space
            vim.api.nvim_win_set_cursor(0, { row, 6 })
            return
        end
        -- 2) Check if line already has a bullet with possible indentation: e.g. "  - Something"
        --    We'll capture "  -" (including trailing spaces) as `bullet` plus the rest as `text`.
        local bullet, text = line:match("^([%s]*[-*]%s+)(.*)$")
        if bullet then
            -- Convert bullet => bullet .. "[ ] " .. text
            local final_line = bullet .. "[ ] " .. text
            vim.api.nvim_set_current_line(final_line)
            -- Place the cursor right after "[ ] "
            -- bullet length + "[ ] " is bullet_len + 4 characters,
            -- but bullet has trailing spaces, so #bullet includes those.
            local bullet_len = #bullet
            -- We want to land after the brackets (four characters: `[ ] `),
            -- so col = bullet_len + 4 (0-based).
            vim.api.nvim_win_set_cursor(0, { row, bullet_len + 4 })
            return
        end
        -- 3) If there's text, but no bullet => prepend "- [ ] "
        --    and place cursor after the brackets
        local final_line = "- [ ] " .. line
        vim.api.nvim_set_current_line(final_line)
        -- "- [ ] " is 6 characters
        vim.api.nvim_win_set_cursor(0, { row, 6 })
    end, { desc = "Convert bullet to a task or insert new task bullet" })
end

local function header_jumps()
    -- HACK: Jump between markdown headings in lazyvim
    -- https://youtu.be/9S7Zli9hzTE
    --
    -- Search UP for a markdown header
    -- Make sure to follow proper markdown convention, and you have a single H1
    -- heading at the very top of the file
    -- This will only search for H2 headings and above
    -- hardtime.nvim causes issues with this key, you have to unrestrict it in the
    -- plugin config
    vim.keymap.set({ "n", "v" }, "gk", function()
        -- `?` - Start a search backwards from the current cursor position.
        -- `^` - Match the beginning of a line.
        -- `##` - Match 2 ## symbols
        -- `\\+` - Match one or more occurrences of prev element (#)
        -- `\\s` - Match exactly one whitespace character following the hashes
        -- `.*` - Match any characters (except newline) following the space
        -- vim.cmd("silent! ?^##\\+\\s.*$")
        local ft = vim.bo.filetype
        if ft == "typst" then
            vim.cmd("silent! ?^==\\+\\s.*$")
            -- Clear the search highlight
            vim.cmd("nohlsearch")
            return
        end -- `$` - Match extends to end of line
        vim.cmd("silent! ?^##\\+\\s.*$")
        -- Clear the search highlight
        vim.cmd("nohlsearch")
    end, { desc = "[P]Go to previous markdown header" })

    -- HACK: Jump between markdown headings in lazyvim
    -- https://youtu.be/9S7Zli9hzTE
    --
    -- Search DOWN for a markdown header
    -- Make sure to follow proper markdown convention, and you have a single H1
    -- heading at the very top of the file
    -- This will only search for H2 headings and above
    -- hardtime.nvim causes issues with this key, you have to unrestrict it in the
    -- plugin config
    vim.keymap.set({ "n", "v" }, "gj", function()
        -- `/` - Start a search forwards from the current cursor position.
        -- `^` - Match the beginning of a line.
        -- `##` - Match 2 ## symbols
        -- `\\+` - Match one or more occurrences of prev element (#)
        -- `\\s` - Match exactly one whitespace character following the hashes
        -- `.*` - Match any characters (except newline) following the space
        -- `$` - Match extends to end of line
        local ft = vim.bo.filetype
        if ft == "typst" then
            vim.cmd("silent! /^==\\+\\s.*$")
            -- Clear the search highlight
            vim.cmd("nohlsearch")
            return
        end
        vim.cmd("silent! /^##\\+\\s.*$")
        -- Clear the search highlight
        vim.cmd("nohlsearch")
    end, { desc = "[P]Go to next markdown header" })
end

markdown_folds()
todo_items()
header_jumps()
