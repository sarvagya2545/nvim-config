return {
    cmd = {
        "clangd",
        "--background-index",
        "--clang-tidy",
        "--completion-style=detailed"
    },
    filetypes = { "cpp", "c" }
}
