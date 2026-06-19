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
                    enabled = true,
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

            -- ---------- (1)+(2): mini.files preview ----------

            local last_preview_path = nil
            local function minifiles_auto_preview()
                local ok, MiniFiles = pcall(require, "mini.files")
                if not ok then
                    return
                end

                local state = MiniFiles.get_explorer_state()
                if not state then
                    return
                end

                -- the window the cursor is actually in (the focused directory window),
                -- NOT whatever buffer the event happened to hand us
                local cur_win = vim.api.nvim_get_current_win()

                -- confirm it's one of mini.files' own windows; bail if focus is elsewhere
                local is_minifiles_win = false
                for _, w in ipairs(state.windows) do
                    if w.win_id == cur_win then
                        is_minifiles_win = true
                        break
                    end
                end
                if not is_minifiles_win then
                    return
                end

                local cur_buf = vim.api.nvim_win_get_buf(cur_win)

                -- get_fs_entry reads the cursor line of this buffer; pcall guards against
                -- non-entry lines (blank/.. rows) and the case where focus is on the
                -- preview window (a file buffer, not a directory buffer)
                local ok_entry, entry = pcall(MiniFiles.get_fs_entry, cur_buf)
                if not ok_entry then
                    return
                end

                if not entry or entry.fs_type ~= "file" or not is_image(entry.path) then
                    if last_preview_path ~= nil then
                        clear_image()
                        last_preview_path = nil
                    end
                    return
                end

                -- already showing this exact image -> do nothing (event is very frequent)
                if entry.path == last_preview_path then
                    return
                end

                -- find mini.files' own preview window for this path
                local prev_win
                for _, w in ipairs(state.windows) do
                    if w.path == entry.path then
                        prev_win = w.win_id
                        break
                    end
                end
                if not prev_win then
                    return
                end -- needs windows.preview = true

                local prev_buf = vim.api.nvim_win_get_buf(prev_win)
                -- wipe the binary bytes mini.files dumped into the preview buffer
                vim.bo[prev_buf].modifiable = true
                vim.api.nvim_buf_set_lines(prev_buf, 0, -1, false, {})
                vim.bo[prev_buf].modifiable = false

                local path = entry.path
                vim.schedule(function()
                    -- re-derive the preview window live; it may have been resized/replaced
                    local st = MiniFiles.get_explorer_state()
                    if not st then
                        return
                    end
                    local pw
                    for _, w in ipairs(st.windows) do
                        if w.path == path then
                            pw = w.win_id
                            break
                        end
                    end
                    if not pw or not vim.api.nvim_win_is_valid(pw) then
                        return
                    end
                    local pb = vim.api.nvim_win_get_buf(pw)
                    vim.bo[pb].modifiable = true
                    vim.api.nvim_buf_set_lines(pb, 0, -1, false, {})
                    vim.bo[pb].modifiable = false
                    render(path, pw, pb)
                    last_preview_path = path
                end)
            end

            -- moving to another entry / closing clears it, so it only shows on K
            vim.api.nvim_create_autocmd("User", {
                pattern = "MiniFilesExplorerClose",
                callback = function()
                    clear_image()
                    last_preview_path = nil
                end,
            })

            vim.api.nvim_create_autocmd("User", {
                pattern = "MiniFilesWindowUpdate",
                callback = function()
                    minifiles_auto_preview()
                end,
            })

            -- ---------- (2)+(3): normal image buffer on K ----------
            local function buffer_show()
                local buf = vim.api.nvim_get_current_buf()
                local win = vim.api.nvim_get_current_win()
                local path = vim.api.nvim_buf_get_name(buf)
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
    {
        "hmdfrds/focal.nvim",
        event = "VeryLazy",
        dependencies = {
            "3rd/image.nvim", -- optional if using chafa backend
        },
        opts = {
            -- See Configuration below
        },
    },
}
