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

        if vim.env.NVIM_CONTEST_MODE == "1" then
            vim.api.nvim_buf_create_user_command(buf, "Run", run, {})
            vim.keymap.set("n", "<leader>r", run, { buffer = buf, desc = "Compile & run C++" })
        end
    end,
})
