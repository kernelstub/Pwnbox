
local capabilities = require("cmp_nvim_lsp").default_capabilities()
vim.lsp.config("*", { capabilities = capabilities })

vim.lsp.config("lua_ls", {
    settings = {
        Lua = {
            runtime = { version = "LuaJIT" },
            diagnostics = { globals = { "vim" } },
            workspace = {
                checkThirdParty = false,
                library = vim.api.nvim_get_runtime_file("", true),
            },
            telemetry = { enable = false },
            format = { enable = false },
            hint = { enable = true },
        },
    },
})

vim.lsp.config("nil_ls", {
    settings = {
        ["nil"] = {
            formatting = { command = { "nixfmt" } },
            diagnostics = { ignored = {} },
        },
    },
})

vim.lsp.config("rust_analyzer", {
    settings = {
        ["rust-analyzer"] = {
            cargo = { allFeatures = true },
            checkOnSave = true,
        },
    },
})

vim.lsp.config("clangd", {
    cmd = { "clangd", "--background-index", "--clang-tidy", "--header-insertion=iwyu" },
})

vim.lsp.enable({
    "nil_ls",
    "lua_ls",
    "bashls",
    "basedpyright",
    "ruff",
    "gopls",
    "rust_analyzer",
    "clangd",
    "ts_ls",
    "html",
    "cssls",
    "jsonls",
    "marksman",
    "taplo",
    "yamlls",
    "dockerls",
    "eslint",
})

vim.diagnostic.config({
    virtual_text = false,
    virtual_lines = false,
    severity_sort = true,
    update_in_insert = false,
    underline = true,
    float = { border = "rounded", source = true, header = "" },
    signs = {
        text = {
            [vim.diagnostic.severity.ERROR] = "E",
            [vim.diagnostic.severity.WARN] = "W",
            [vim.diagnostic.severity.INFO] = "I",
            [vim.diagnostic.severity.HINT] = "H",
        },
    },
})

vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("pwnbox_lsp_attach", { clear = true }),
    callback = function(event)
        local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = event.buf, desc = desc })
        end

        map("n", "<F2>", vim.lsp.buf.rename, "Rename symbol")
        map("n", "<F12>", vim.lsp.buf.definition, "Go to definition")
        map("n", "<S-F12>", vim.lsp.buf.references, "Find all references")
        map("n", "<C-S-o>", "<cmd>Telescope lsp_document_symbols<cr>", "Go to symbol in file")
        map("n", "<C-S-r>", "<cmd>Telescope lsp_references<cr>", "Find all references")

        map("n", "gd", vim.lsp.buf.definition, "Go to definition")
        map("n", "gD", vim.lsp.buf.declaration, "Go to declaration")
        map("n", "gi", vim.lsp.buf.implementation, "Go to implementation")
        map("n", "gy", vim.lsp.buf.type_definition, "Go to type definition")
        map("n", "gr", vim.lsp.buf.references, "Go to references")
        map("n", "K", vim.lsp.buf.hover, "Hover documentation")
        map("n", "<C-k>", vim.lsp.buf.signature_help, "Signature help")
        map("n", "<leader>rn", vim.lsp.buf.rename, "Rename symbol")
        map({ "n", "v" }, "<leader>ca", vim.lsp.buf.code_action, "Code action")
        map("n", "<leader>ld", vim.diagnostic.open_float, "Line diagnostics")
        map("n", "<leader>lj", function()
            vim.diagnostic.jump({ count = 1 })
        end, "Next diagnostic")
        map("n", "<leader>lk", function()
            vim.diagnostic.jump({ count = -1 })
        end, "Previous diagnostic")
    end,
})
