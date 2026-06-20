-- https://github.com/3rd/image.nvim
--
-- Filename: ~/github/dotfiles-latest/neovim/nvim-lazyvim/lua/plugins/image-nvim.lua
-- ~/github/dotfiles-latest/neovim/nvim-lazyvim/lua/plugins/image-nvim.lua

-- For dependencies see
-- `~/github/dotfiles-latest/neovim/nvim-lazyvim/README.md`
--
-- -- Uncomment the following 2 lines if you use the local luarocks installation
-- -- Leave them commented to instead use `luarocks.nvim`
-- -- instead of luarocks.nvim
-- Notice that in the following 2 commands I'm using luaver
-- package.path = package.path
--   .. ";"
--   .. vim.fn.expand("$HOME")
--   .. "/.luaver/luarocks/3.11.0_5.1/share/lua/5.1/magick/?/init.lua"
-- package.path = package.path
--   .. ";"
--   .. vim.fn.expand("$HOME")
--   .. "/.luaver/luarocks/3.11.0_5.1/share/lua/5.1/magick/?.lua"
--
-- -- Here I'm not using luaver, but instead installed lua and luarocks directly through
-- -- homebrew
-- package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?/init.lua"
-- package.path = package.path .. ";" .. vim.fn.expand("$HOME") .. "/.luarocks/share/lua/5.1/?.lua"

-- local log = function(line, tag)
--     if tag ~= nil then
--         line = line .. tag
--     end
--     vim.fn.writefile({ line }, "/tmp/minifiles_preview.log", "a")
-- end
return {
    {
        -- luarocks.nvim is a Neovim plugin designed to streamline the installation
        -- of luarocks packages directly within Neovim. It simplifies the process
        -- of managing Lua dependencies, ensuring a hassle-free experience for
        -- Neovim users.
        -- https://github.com/vhyrro/luarocks.nvim
        "vhyrro/luarocks.nvim",
        -- this plugin needs to run before anything else
        priority = 1001,
        opts = {
            rocks = { "magick", "dkjson" },
        },
    },
    {
        "3rd/image.nvim",
        dependencies = { "nvim-mini/mini.files" },
        opts = {
            backend = "kitty",
            kitty_method = "normal",
            hijack_file_patterns = {},
            integrations = {
                -- Notice these are the settings for markdown files
                markdown = {
                    -- Auto-rendering is turned OFF on purpose: image.nvim has no
                    -- native "render on keypress", so instead of letting images pop
                    -- automatically at the cursor, we preview them on demand with `K`
                    -- (see the FileType markdown keymap in the config function below).
                    enabled = false,
                    clear_in_insert_mode = false,
                    -- Set this to false if you don't want to render images coming from
                    -- a URL
                    download_remote_images = true,
                    -- Change this if you would only like to render the image where the
                    -- cursor is at
                    -- I set this to true, because if the file has way too many images
                    -- it will be laggy and will take time for the initial load
                    only_render_image_at_cursor = true,
                    -- markdown extensions (ie. quarto) can go here
                    filetypes = { "markdown" },
                },
            },
            max_width = nil,
            max_height = nil,
            max_width_window_percentage = nil,

            -- This is what I changed to make my images look smaller, like a
            -- thumbnail, the default value is 50
            -- max_height_window_percentage = 20,
            max_height_window_percentage = 40,

            -- toggles images when windows are overlapped
            window_overlap_clear_enabled = false,
            window_overlap_clear_ft_ignore = { "cmp_menu", "cmp_docs", "" },

            -- auto show/hide images when the editor gains/looses focus
            editor_only_render_when_focused = true,

            -- auto show/hide images in the correct tmux window
            -- In the tmux.conf add `set -g visual-activity off`
            tmux_show_only_in_active_window = true,
        },
        config = function(_, opts)
            local image = require("image")
            image.setup(opts)

            -- ---------- shared helpers ----------
            local rendered = nil -- currently shown image object

            local IMG_EXT = { png = 1, jpg = 1, jpeg = 1, gif = 1, webp = 1, avif = 1 }
            local function is_image(path)
                if not path then
                    return false
                end
                local ext = path:match("%.([%w]+)$")
                return ext ~= nil and IMG_EXT[ext:lower()] ~= nil and IMG_EXT[ext:lower()] == 1
            end

            local function clear_image()
                if rendered then
                    pcall(function()
                        rendered:clear()
                    end)
                    rendered = nil
                end
            end

            local function render(path, win, buf)
                clear_image()
                if not is_image(path) then
                    return
                end
                local ok, img = pcall(image.from_file, path, { window = win, buffer = buf })
                if not (ok and img) then
                    return
                end
                rendered = img
                img.max_width_window_percentage = 100
                img.max_height_window_percentage = 100
                local w = vim.api.nvim_win_get_width(win)
                local h = vim.api.nvim_win_get_height(win)
                pcall(function()
                    img:render({ x = 0, y = 0, width = w, height = h })
                end)
            end

            -- ---------- normal image buffer on K ----------
            local function buffer_show()
                local buf = vim.api.nvim_get_current_buf()
                local win = vim.api.nvim_get_current_win()
                local path = vim.api.nvim_buf_get_name(buf)
                -- Only act on real, on-disk files. Skip plugin/scratch buffers such
                -- as mini.files previews, which are named `minifiles://.../foo.png`:
                -- the tail matches the image autocmd pattern, but flipping
                -- `modifiable` here leaves the buffer locked, and mini.files' own
                -- refresh after a sync then fails to rewrite it (E5108).
                if vim.bo[buf].buftype ~= "" or path:find("://", 1, true) then
                    return
                end
                if not is_image(path) then
                    return
                end

                -- clean the binary nvim loaded so only the image shows
                vim.bo[buf].modifiable = true
                vim.api.nvim_buf_set_lines(buf, 0, -1, false, {})
                vim.bo[buf].modified = false
                vim.bo[buf].modifiable = false

                render(path, win, buf)
            end

            local img_glob = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" }
            vim.api.nvim_create_autocmd("BufWinEnter", {
                pattern = img_glob,
                callback = buffer_show,
            })
            vim.api.nvim_create_autocmd({ "BufLeave", "WinClosed" }, {
                pattern = img_glob,
                callback = clear_image,
            })

            -- ---------- markdown image preview on K ----------
            -- image.nvim has no native "render on keypress", so this is custom:
            -- in a markdown buffer, put the cursor on an image link `![alt](path)`
            -- and press K to preview that image in a centered floating window.
            -- Auto-rendering is disabled (integrations.markdown.enabled = false), so
            -- images only ever show on demand.

            -- decode %XX escapes (img-clip can url-encode paths)
            local function url_decode(str)
                return (
                    str:gsub("%%(%x%x)", function(h)
                        return string.char(tonumber(h, 16))
                    end)
                )
            end

            -- return the image path from the `![...](path)` link under the cursor, or nil
            local function md_image_under_cursor()
                local line = vim.api.nvim_get_current_line()
                local col = vim.api.nvim_win_get_cursor(0)[2] + 1 -- 1-indexed
                local from = 1
                while true do
                    local s, e, path = line:find("!%[[^%]]*%]%(([^)]+)%)", from)
                    if not s then
                        return nil
                    end
                    if col >= s and col <= e then
                        -- drop an optional `  "title"` suffix, then trim
                        path = path:gsub("%s+[\"'].*$", "")
                        return vim.trim(path)
                    end
                    from = e + 1
                end
            end

            -- terminal cell pixel size; lets us size the float to the image's
            -- true aspect ratio instead of a fixed box
            local function cell_size()
                local ok, term = pcall(function()
                    return require("image.utils").term.get_size()
                end)
                if ok and term and (term.cell_width or 0) > 0 and (term.cell_height or 0) > 0 then
                    return term.cell_width, term.cell_height
                end
                return 8, 16 -- sane fallback (matches image.nvim's own SSH fallback)
            end

            -- given image pixel dims, return the float's content size in cells that
            -- preserves the image's aspect ratio and fits within max_w x max_h
            -- (scaled down to fit, never upscaled past natural size)
            local function fit_to_image(iw, ih, max_w, max_h)
                if not iw or not ih or iw <= 0 or ih <= 0 then
                    return max_w, max_h
                end
                local cw, ch = cell_size()
                local nat_w = iw / cw -- natural width in cells
                local nat_h = ih / ch -- natural height in cells
                local scale = math.min(max_w / nat_w, max_h / nat_h, 1.0)
                local w = math.max(1, math.floor(nat_w * scale + 0.5))
                local h = math.max(1, math.floor(nat_h * scale + 0.5))
                return w, h
            end

            -- open a centered float at max size; closes on q / <esc>
            local function open_float(max_w, max_h, title)
                clear_image()
                local buf = vim.api.nvim_create_buf(false, true)
                local win = vim.api.nvim_open_win(buf, true, {
                    relative = "editor",
                    width = max_w,
                    height = max_h,
                    row = math.floor((vim.o.lines - max_h) / 2),
                    col = math.floor((vim.o.columns - max_w) / 2),
                    style = "minimal",
                    border = "rounded",
                    title = title and (" " .. title .. " ") or nil,
                    title_pos = title and "center" or nil,
                })
                local function close()
                    clear_image()
                    if vim.api.nvim_win_is_valid(win) then
                        vim.api.nvim_win_close(win, true)
                    end
                end
                vim.keymap.set("n", "<esc>", close, { buffer = buf, noremap = true, silent = true })
                vim.keymap.set("n", "q", close, { buffer = buf, noremap = true, silent = true })
                return win, buf
            end

            -- shrink the float to hug `img`, then render it edge-to-edge
            local function fit_and_render(win, img, max_w, max_h)
                if not (img and vim.api.nvim_win_is_valid(win)) then
                    return
                end
                local w, h = fit_to_image(img.image_width, img.image_height, max_w, max_h)
                vim.api.nvim_win_set_config(win, {
                    relative = "editor",
                    width = w,
                    height = h,
                    row = math.floor((vim.o.lines - h) / 2),
                    col = math.floor((vim.o.columns - w) / 2),
                })
                rendered = img
                img.max_width_window_percentage = 100
                img.max_height_window_percentage = 100
                pcall(function()
                    img:render({ x = 0, y = 0, width = w, height = h })
                end)
            end

            local function preview_markdown_image()
                local raw = md_image_under_cursor()
                if not raw then
                    -- not on an image link -> fall back to the usual K behavior
                    if #vim.lsp.get_clients({ bufnr = 0 }) > 0 then
                        pcall(vim.lsp.buf.hover)
                    else
                        pcall(vim.cmd, "normal! K")
                    end
                    return
                end

                -- generous max box; the float is then shrunk to the image aspect
                local max_w = math.floor(vim.o.columns * 0.85)
                local max_h = math.floor(vim.o.lines * 0.85)

                -- remote image -> stream it in with from_url, size in the callback
                if raw:match("^https?://") then
                    local win, buf = open_float(max_w, max_h, raw:match("[^/]+$"))
                    pcall(image.from_url, raw, { window = win, buffer = buf }, function(img)
                        fit_and_render(win, img, max_w, max_h)
                    end)
                    return
                end

                -- local image -> resolve relative to the markdown file's directory
                local path = url_decode(raw)
                if path:sub(1, 1) ~= "/" and path:sub(1, 1) ~= "~" then
                    path = vim.fn.expand("%:p:h") .. "/" .. path
                end
                path = vim.fn.fnamemodify(vim.fn.expand(path), ":p")

                if vim.fn.filereadable(path) == 0 then
                    vim.notify("Image not found: " .. path, vim.log.levels.WARN)
                    return
                end
                if not is_image(path) then
                    vim.notify("Not a supported image: " .. path, vim.log.levels.WARN)
                    return
                end

                local win, buf = open_float(max_w, max_h, vim.fn.fnamemodify(path, ":t"))
                local ok, img = pcall(image.from_file, path, { window = win, buffer = buf })
                if ok and img then
                    fit_and_render(win, img, max_w, max_h)
                else
                    vim.notify("Failed to load image: " .. path, vim.log.levels.WARN)
                    if vim.api.nvim_win_is_valid(win) then
                        vim.api.nvim_win_close(win, true)
                    end
                end
            end

            vim.api.nvim_create_autocmd("FileType", {
                pattern = { "markdown", "quarto", "vimwiki" },
                callback = function(args)
                    vim.keymap.set("n", "K", preview_markdown_image, {
                        buffer = args.buf,
                        noremap = true,
                        silent = true,
                        desc = "Preview image link under cursor",
                    })
                end,
            })

            -- ---------- (4): manual preview keymaps inside mini.files ----------
            -- These are buffer-local, so they only exist inside a mini.files window.
            -- They are registered on every mini.files buffer via MiniFilesBufferCreate.
            --   <space>i : preview the entry under the cursor with macOS Quick Look
            --   <M-i>    : preview the image under the cursor in a centered floating window
            -- Quick Look idea credit: video https://youtu.be/BzblG2eV8dU
            vim.api.nvim_create_autocmd("User", {
                pattern = "MiniFilesBufferCreate",
                callback = function(args)
                    local buf_id = args.data.buf_id
                    local MiniFiles = require("mini.files")

                    -- <space>i : macOS Quick Look (handles images, PDFs, video, etc.)
                    vim.keymap.set("n", "<space>i", function()
                        local entry = MiniFiles.get_fs_entry()
                        if not entry then
                            vim.notify("No file selected", vim.log.levels.WARN)
                            return
                        end
                        -- Open the file in Quick Look (stdout/stderr silenced; qlmanage is noisy)
                        vim.system({ "qlmanage", "-p", entry.path }, { stdout = false, stderr = false })
                        -- qlmanage opens in the background, so bring it to the front
                        vim.defer_fn(function()
                            vim.system({ "osascript", "-e", 'tell application "qlmanage" to activate' })
                        end, 200)
                    end, {
                        buffer = buf_id,
                        noremap = true,
                        silent = true,
                        desc = "[P]Preview with macOS Quick Look",
                    })

                    -- <M-i> : render the image under the cursor in a centered floating window
                    vim.keymap.set("n", "<M-i>", function()
                        local entry = MiniFiles.get_fs_entry()
                        if not entry or entry.fs_type ~= "file" or not is_image(entry.path) then
                            vim.notify("Not an image file", vim.log.levels.WARN)
                            return
                        end

                        -- remember where we are so we can restore mini.files afterwards
                        local current_dir = vim.fn.fnamemodify(entry.path, ":h")
                        local focused_name = vim.fn.fnamemodify(entry.path, ":t")
                        local path = entry.path

                        -- clear any image currently rendered so we don't draw twice
                        clear_image()

                        local width = math.floor(vim.o.columns * 0.6)
                        local height = math.floor(vim.o.lines * 0.6)
                        local col = math.floor((vim.o.columns - width) / 2)
                        local row = math.floor((vim.o.lines - height) / 2)

                        local buf = vim.api.nvim_create_buf(false, true)
                        local win = vim.api.nvim_open_win(buf, true, {
                            relative = "editor",
                            row = row,
                            col = col,
                            width = width,
                            height = height,
                            style = "minimal",
                            border = "rounded",
                            title = " " .. focused_name .. " ",
                            title_pos = "center",
                        })

                        -- reuse the shared render() helper -> sets `rendered`
                        render(path, win, buf)

                        local function close_and_restore()
                            clear_image()
                            if vim.api.nvim_win_is_valid(win) then
                                vim.api.nvim_win_close(win, true)
                            end
                            -- reopen mini.files in the same dir and land on the same file
                            MiniFiles.open(current_dir, true)
                            vim.defer_fn(function()
                                local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
                                for i, line in ipairs(lines) do
                                    if line:find(focused_name, 1, true) then
                                        pcall(vim.api.nvim_win_set_cursor, 0, { i, 0 })
                                        break
                                    end
                                end
                            end, 50)
                        end

                        vim.keymap.set("n", "<esc>", close_and_restore, { buffer = buf, noremap = true, silent = true })
                        vim.keymap.set("n", "q", close_and_restore, { buffer = buf, noremap = true, silent = true })
                    end, {
                        buffer = buf_id,
                        noremap = true,
                        silent = true,
                        desc = "[P]Preview image in popup",
                    })
                end,
            })
        end,
    },
    {
        "HakonHarnes/img-clip.nvim",
        event = "VeryLazy",
        opts = {
            -- add options here
            -- or leave it empty to use the default settings
            default = {

                -- file and directory options
                -- expands dir_path to an absolute path
                -- When you paste a new image, and you hover over its path, instead of:
                -- test-images-img/2024-06-03-at-10-58-55.webp
                -- You would see the entire path:
                -- /Users/linkarzu/github/obsidian_main/999-test/test-images-img/2024-06-03-at-10-58-55.webp
                --
                -- IN MY CASE I DON'T WANT TO USE ABSOLUTE PATHS
                -- if I switch to a nother computer and I have a different username,
                -- therefore a different home directory, that's a problem because the
                -- absolute paths will be pointing to a different directory
                use_absolute_path = false, ---@type boolean

                -- make dir_path relative to current file rather than the cwd
                -- To see your current working directory run `:pwd`
                -- So if this is set to false, the image will be created in that cwd
                -- In my case, I want images to be where the file is, so I set it to true
                relative_to_current_file = true, ---@type boolean

                -- I want to save the images in a directory named after the current file,
                -- but I want the name of the dir to end with `-img`
                dir_path = function()
                    return vim.fn.expand("%:t:r") .. "-img"
                end,

                -- If you want to get prompted for the filename when pasting an image
                -- This is the actual name that the physical file will have
                -- If you set it to true, enter the name without spaces or extension `test-image-1`
                -- Remember we specified the extension above
                --
                -- I don't want to give my images a name, but instead autofill it using
                -- the date and time as shown on `file_name` below
                prompt_for_file_name = false, ---@type boolean
                file_name = "%Y-%m-%d-at-%H-%M-%S", ---@type string

                -- -- Set the extension that the image file will have
                -- -- I'm also specifying the image options with the `process_cmd`
                -- -- Notice that I HAVE to convert the images to the desired format
                -- -- If you don't specify the output format, you won't see the size decrease

                -- extension = "avif", ---@type string
                -- process_cmd = "convert - -quality 75 avif:-", ---@type string

                -- extension = "webp", ---@type string
                -- process_cmd = "convert - -quality 75 webp:-", ---@type string

                extension = "png", ---@type string
                -- process_cmd = "convert - -quality 75 png:-", ---@type string

                -- extension = "jpg", ---@type string
                -- process_cmd = "convert - -quality 75 jpg:-", ---@type string

                -- -- Here are other conversion options to play around
                -- -- Notice that with this other option you resize all the images
                -- process_cmd = "convert - -quality 75 -resize 50% png:-", ---@type string

                -- -- Other parameters I found in stackoverflow
                -- -- https://stackoverflow.com/a/27269260
                -- --
                -- -- -depth value
                -- -- Color depth is the number of bits per channel for each pixel. For
                -- -- example, for a depth of 16 using RGB, each channel of Red, Green, and
                -- -- Blue can range from 0 to 2^16-1 (65535). Use this option to specify
                -- -- the depth of raw images formats whose depth is unknown such as GRAY,
                -- -- RGB, or CMYK, or to change the depth of any image after it has been read.
                -- --
                -- -- compression-filter (filter-type)
                -- -- compression level, which is 0 (worst but fastest compression) to 9 (best but slowest)
                -- process_cmd = "convert - -depth 24 -define png:compression-filter=5 -define png:compression-level=9 -define png:compression-strategy=1 png:-",
                --
                -- -- These are for jpegs
                -- process_cmd = "convert - -sampling-factor 4:2:0 -strip -interlace JPEG -colorspace RGB -quality 75 jpg:-",
                -- process_cmd = "convert - -strip -interlace Plane -gaussian-blur 0.05 -quality 75 jpg:-",
                --
            },

            -- filetype specific options
            filetypes = {
                markdown = {
                    -- encode spaces and special characters in file path
                    url_encode_path = true, ---@type boolean

                    -- -- The template is what specifies how the alternative text and path
                    -- -- of the image will appear in your file
                    --
                    -- -- $CURSOR will paste the image and place your cursor in that part so
                    -- -- you can type the "alternative text", keep in mind that this will
                    -- -- not affect the name that the image physically has
                    template = "![$CURSOR]($FILE_PATH)", ---@type string
                    --
                    -- -- This will just statically type "Image" in the alternative text
                    -- template = "![Image]($FILE_PATH)", ---@type string
                    --
                    -- -- This will dynamically configure the alternative text to show the
                    -- -- same that you configured as the "file_name" above
                    -- template = "![$FILE_NAME]($FILE_PATH)", ---@type string
                },
            },
        },
        keys = {
            -- suggested keymap
            { "<leader>v", "<cmd>PasteImage<cr>", desc = "Paste image from system clipboard" },
        },
    },
}
