vim.api.nvim_create_autocmd("TextYankPost", {
    desc = "Highlight when yanking text",
    callback = function()
        vim.hl.on_yank()
    end,
})

-- RUN C++ CODE in CONTEST_MODE
vim.api.nvim_create_autocmd("FileType", {
    pattern = "cpp",
    callback = function(args)
        local buf = args.buf

        local function run()
            vim.cmd("silent! write")

            local src = vim.api.nvim_buf_get_name(buf)
            local dir = vim.fn.fnamemodify(src, ":h")
            local bin = dir .. "/out"

            vim.notify("Compiling...", vim.log.levels.INFO, { title = "Run" })

            -- compile (async): g++-13 -std=c++20 code.cpp -o out
            vim.system({ "g++-13", "-std=c++20", src, "-o", bin }, { text = true }, function(compile)
                if compile.code ~= 0 then
                    vim.schedule(function()
                        vim.notify(compile.stderr, vim.log.levels.ERROR, { title = "Compile failed" })
                    end)
                    return
                end

                -- run (async) from the file's own directory
                local start = vim.loop.hrtime()
                vim.system({ bin }, { cwd = dir, text = true }, function(result)
                    local ms = (vim.loop.hrtime() - start) / 1e6
                    vim.schedule(function()
                        vim.cmd("checktime") -- reload output.txt split
                        if result.code ~= 0 then
                            vim.notify(
                                ("Runtime error (exit %d) in %.0f ms\n%s"):format(result.code, ms, result.stderr or ""),
                                vim.log.levels.WARN,
                                { title = "Run" }
                            )
                        else
                            vim.notify(("Done in %.0f ms"):format(ms), vim.log.levels.INFO, { title = "Run" })
                        end
                    end)
                end)
            end)
        end

        vim.api.nvim_buf_create_user_command(buf, "Run", run, {})

        if vim.env.NVIM_CONTEST_MODE == "1" then
            vim.keymap.set("n", "<leader>r", run, { buffer = buf, desc = "Compile & run C++" })
        end
    end,
})

-- MARKDOWN FOLDS

vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    callback = function(args)
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
    end,
})
