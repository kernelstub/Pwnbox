local palette = require("config.theme").palette

require("nvim-web-devicons").setup({
    color_icons = false,
    default = true,
})
vim.api.nvim_set_hl(0, "DevIconDefault", { fg = palette.muted })

local wk = require("which-key")
wk.setup({
    preset = "classic",
    delay = 300,
    icons = { mappings = false },
})
wk.add({
    { "<leader>b", group = "Buffers" },
    { "<leader>c", group = "Code" },
    { "<leader>f", group = "Find" },
    { "<leader>g", group = "Git" },
    { "<leader>q", group = "Session / Quit" },
    { "<leader>t", group = "Terminal" },
    { "<leader>u", group = "UI" },
    { "<leader>w", group = "Windows" },
    { "<leader>x", group = "Diagnostics" },
    { "<C-b>",     desc = "Toggle sidebar" },
    { "<C-p>",     desc = "Quick open" },
    { "<C-j>",     desc = "Toggle terminal" },
    { "<C-`>",     desc = "Toggle terminal" },
})

local notify = require("notify")
local function setup_notify()
    notify.setup({
        background_colour = palette.bg_alt,
        fps = 60,
        render = "minimal",
        stages = "fade_in_slide_out",
        timeout = 2500,
        max_width = 60,
        on_open = function(win)
            vim.api.nvim_win_set_config(win, { border = "rounded" })
        end,
    })
end
setup_notify()
require("config.theme").on_reload(setup_notify)
vim.notify = notify

local telescope = require("telescope")
local actions = require("telescope.actions")
telescope.setup({
    defaults = {
        prompt_prefix = "  ",
        selection_caret = "  ",
        path_display = { "smart" },
        sorting_strategy = "ascending",
        layout_strategy = "horizontal",
        layout_config = {
            prompt_position = "top",
            horizontal = { preview_width = 0.55 },
        },
        color_devicons = false,
        winblend = 0,
        border = true,
        borderchars = { "─", "│", "─", "│", "╭", "╮", "╯", "╰" },
        mappings = {
            i = {
                ["<C-j>"] = actions.move_selection_next,
                ["<C-k>"] = actions.move_selection_previous,
                ["<C-u>"] = false,
                ["<C-d>"] = false,
                ["<Esc>"] = actions.close,
            },
            n = { ["q"] = actions.close },
        },
        file_ignore_patterns = { "^.git/", "node_modules/", "target/", "dist/" },
    },
    pickers = {
        find_files = { hidden = true },
        buffers = { sort_mru = true, ignore_current_buffer = true },
    },
})

require("gitsigns").setup({
    signs = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "▁" },
        topdelete = { text = "▔" },
        changedelete = { text = "▎" },
        untracked = { text = "│" },
    },
    signs_staged = {
        add = { text = "▎" },
        change = { text = "▎" },
        delete = { text = "▁" },
        topdelete = { text = "▔" },
        changedelete = { text = "▎" },
    },
    current_line_blame_opts = { virt_text_pos = "eol", delay = 500 },
    on_attach = function(bufnr)
        local gs = package.loaded.gitsigns
        local function map(mode, lhs, rhs, desc)
            vim.keymap.set(mode, lhs, rhs, { buffer = bufnr, desc = desc })
        end
        map("n", "]c", function()
            if vim.wo.diff then return "]c" end
            vim.schedule(gs.next_hunk)
            return "<Ignore>"
        end, "Next hunk")
        map("n", "[c", function()
            if vim.wo.diff then return "[c" end
            vim.schedule(gs.prev_hunk)
            return "<Ignore>"
        end, "Previous hunk")
        map("n", "<leader>ghs", gs.stage_hunk, "Stage hunk")
        map("v", "<leader>ghs", function() gs.stage_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Stage hunk")
        map("n", "<leader>ghr", gs.reset_hunk, "Reset hunk")
        map("v", "<leader>ghr", function() gs.reset_hunk({ vim.fn.line("."), vim.fn.line("v") }) end, "Reset hunk")
        map("n", "<leader>ghu", gs.undo_stage_hunk, "Undo stage hunk")
        map("n", "<leader>ghp", gs.preview_hunk, "Preview hunk")
        map("n", "<leader>ghb", function() gs.blame_line({ full = true }) end, "Blame line")
        map("n", "<leader>ghd", gs.diffthis, "Diff this")
    end,
})

require("neogit").setup({
    disable_hint = true,
    graph_style = "unicode",
    commit_order = "topo",
    kind = "split",
    commit_editor = { kind = "split", spell_check = true },
    commit_select_view = { kind = "split" },
    commit_view = { kind = "vsplit" },
    log_view = { kind = "split" },
    integrations = {
        telescope = true,
        diffview = false,
    },
})

local function lualine_theme()
    return {
        normal = {
            a = { fg = palette.bg, bg = palette.bright, gui = "bold" },
            b = { fg = palette.fg, bg = palette.bg_alt },
            c = { fg = palette.muted, bg = palette.bg },
        },
        insert = {
            a = { fg = palette.bg, bg = palette.white, gui = "bold" },
            b = { fg = palette.fg, bg = palette.bg_alt },
            c = { fg = palette.muted, bg = palette.bg },
        },
        visual = {
            a = { fg = palette.bg, bg = palette.muted, gui = "bold" },
            b = { fg = palette.fg, bg = palette.bg_alt },
            c = { fg = palette.muted, bg = palette.bg },
        },
        replace = {
            a = { fg = palette.bg, bg = palette.white, gui = "bold" },
            b = { fg = palette.fg, bg = palette.bg_alt },
            c = { fg = palette.muted, bg = palette.bg },
        },
        command = {
            a = { fg = palette.bg, bg = palette.bright, gui = "bold" },
            b = { fg = palette.fg, bg = palette.bg_alt },
            c = { fg = palette.muted, bg = palette.bg },
        },
        terminal = {
            a = { fg = palette.bg, bg = palette.bright, gui = "bold" },
            b = { fg = palette.fg, bg = palette.bg_alt },
            c = { fg = palette.muted, bg = palette.bg },
        },
        inactive = {
            a = { fg = palette.dim, bg = palette.bg_alt },
            b = { fg = palette.dim, bg = palette.bg_alt },
            c = { fg = palette.dim, bg = palette.bg },
        },
    }
end

local function setup_lualine()
    require("lualine").setup({
        options = {
            theme = lualine_theme(),
            globalstatus = true,
            icons_enabled = false,
            section_separators = "",
            component_separators = "│",
            disabled_filetypes = { statusline = { "alpha", "dashboard", "oil", "neo-tree" } },
        },
        sections = {
            lualine_a = { { "mode", fmt = function(s) return s:sub(1, 1) end } },
            lualine_b = { "branch", "diff", "diagnostics" },
            lualine_c = {
                { "filename", path = 1, symbols = { modified = " ●", readonly = "  ", unnamed = "[No Name]" } },
            },
            lualine_x = { "filetype", "fileformat", "encoding" },
            lualine_y = { "searchcount", "progress" },
            lualine_z = { "location" },
        },
    })
end
setup_lualine()
require("config.theme").on_reload(setup_lualine)

require("bufferline").setup({
    options = {
        mode = "buffers",
        separator_style = "thin",
        show_buffer_close_icons = false,
        show_close_icon = false,
        always_show_bufferline = false,
        diagnostics = "nvim_lsp",
        indicator = { style = "underline" },
        offsets = {
            { filetype = "neo-tree", text = "Explorer", text_align = "left", separator = true },
        },
    },
})

require("ibl").setup({
    indent = { char = "│", tab_char = "│" },
    scope = { enabled = true, show_start = false, show_end = false, char = "│" },
    exclude = {
        filetypes = {
            "alpha",
            "dashboard",
            "help",
            "lspinfo",
            "man",
            "markdown",
            "neo-tree",
            "oil",
            "qf",
            "toggleterm",
        },
    },
})

local npairs = require("nvim-autopairs")
npairs.setup({
    check_ts = true,
    enable_check_bracket_line = false,
    ignored_next_char = "[%w%.]",
})
local cmp = require("cmp")
require("cmp").event:on("confirm_done", require("nvim-autopairs.completion.cmp").on_confirm_done())

require("Comment").setup({
    padding = { left = " ", right = " " },
    sticky = true,
})
require("nvim-surround").setup({})

require("toggleterm").setup({
    size = function(term)
        if term.direction == "horizontal" then
            return 15
        elseif term.direction == "vertical" then
            return math.floor(vim.o.columns * 0.4)
        end
        return 20
    end,
    open_mapping = false,
    direction = "float",
    shade_terminals = false,
    start_in_insert = true,
    persist_size = true,
    close_on_exit = true,
    float_opts = { border = "rounded", winblend = 0 },
})

require("oil").setup({
    default_file_explorer = false,
    columns = { "icon", "size" },
    delete_to_trash = true,
    skip_confirm_for_simple_edits = true,
    view_options = { show_hidden = true, natural_order = true },
    float = { padding = 2, max_width = 0.6, max_height = 0.6, border = "rounded" },
})

require("neo-tree").setup({
    close_if_last_window = true,
    enable_git_status = true,
    enable_diagnostics = true,
    sort_case_insensitive = true,
    open_files_in_last_window = true,
    open_files_do_not_replace_types = { "terminal", "trouble", "qf", "toggleterm" },
    default_component_configs = {
        indent = { with_expanders = true, expander_collapsed = "", expander_expanded = "" },
        git_status = {
            symbols = {
                added = "",
                modified = "",
                deleted = "✖",
                renamed = "󰁕",
                untracked = "",
                ignored = "◌",
                unstaged = "✗",
                staged = "✓",
                conflict = "",
            },
        },
    },
    window = {
        position = "left",
        width = 34,
        mapping_options = { noremap = true, nowait = true },
        mappings = {
            ["<space>"] = { "toggle_node", nowait = false },
            ["<cr>"] = "open",
            ["l"] = "open",
            ["h"] = "close_node",
            ["S"] = "open_split",
            ["s"] = "open_vsplit",
            ["t"] = "open_tabnew",
            ["R"] = "refresh",
            ["q"] = "close_window",
        },
    },
    filesystem = {
        hijack_netrw_behavior = "open_default",
        follow_current_file = { enabled = true, leave_dirs_open = false },
        filtered_items = {
            visible = false,
            hide_dotfiles = false,
            hide_gitignored = false,
        },
        window = {
            mappings = {
                ["<bs>"] = "navigate_up",
                ["."] = "set_root",
                ["H"] = "toggle_hidden",
                ["/"] = "fuzzy_finder",
                ["f"] = "filter_on_submit",
                ["<c-c>"] = "clear_filter",
            },
        },
    },
})

require("trouble").setup({
    auto_close = true,
    auto_preview = true,
    use_diagnostic_signs = true,
})

require("conform").setup({
    formatters_by_ft = {
        lua = { "stylua" },
        nix = { "nixfmt" },
        python = { "ruff_format" },
        sh = { "shfmt" },
        bash = { "shfmt" },
        go = { "gofmt" },
        rust = { "rustfmt" },
        c = { "clang-format" },
        cpp = { "clang-format" },
        javascript = { "prettier" },
        javascriptreact = { "prettier" },
        typescript = { "prettier" },
        typescriptreact = { "prettier" },
        json = { "prettier" },
        jsonc = { "prettier" },
        yaml = { "prettier" },
        html = { "prettier" },
        css = { "prettier" },
        scss = { "prettier" },
        markdown = { "prettier" },
        toml = { "taplo" },
    },
    format_on_save = { timeout_ms = 1000, lsp_format = "fallback" },
})

local lint = require("lint")
lint.linters_by_ft = {
    python = { "ruff" },
    sh = { "shellcheck" },
    bash = { "shellcheck" },
}
vim.api.nvim_create_autocmd({ "BufWritePost", "BufReadPost", "InsertLeave" }, {
    group = vim.api.nvim_create_augroup("pwnbox_lint", { clear = true }),
    callback = function()
        require("lint").try_lint()
    end,
})

require("tiny-inline-diagnostic").setup({
    preset = "classic",
    transparent_bg = true,
    options = {
        show_source = { enabled = true, if_many = true },
        show_code = false,
        show_related = { enabled = true, max_count = 3 },
        throttle = 20,
        softwrap = 30,
    },
    hi = {
        error = "DiagnosticError",
        warn = "DiagnosticWarn",
        info = "DiagnosticInfo",
        hint = "DiagnosticHint",
        arrow = "NonText",
        background = "CursorLine",
        mixing_color = "Normal",
    },
})

require("persistence").setup({})

local luasnip = require("luasnip")
require("luasnip.loaders.from_vscode").lazy_load()

local kind_icons = {
    Text = "T",
    Method = "M",
    Function = "F",
    Constructor = "C",
    Field = "f",
    Variable = "V",
    Class = "K",
    Interface = "I",
    Module = "m",
    Property = "p",
    Unit = "U",
    Value = "v",
    Enum = "E",
    Keyword = "k",
    Snippet = "S",
    Color = "c",
    File = "F",
    Reference = "R",
    Folder = "D",
    EnumMember = "e",
    Constant = "C",
    Struct = "S",
    Event = "E",
    Operator = "O",
    TypeParameter = "T",
}

cmp.setup({
    snippet = {
        expand = function(args)
            luasnip.lsp_expand(args.body)
        end,
    },
    completion = {
        autocomplete = { cmp.TriggerEvent.TextChanged },
        completeopt = "menu,menuone,noselect",
    },
    window = {
        completion = cmp.config.window.bordered(),
        documentation = cmp.config.window.bordered(),
    },
    mapping = cmp.mapping.preset.insert({
        ["<C-b>"] = cmp.mapping.scroll_docs(-4),
        ["<C-f>"] = cmp.mapping.scroll_docs(4),
        ["<C-Space>"] = cmp.mapping.complete(),
        ["<C-e>"] = cmp.mapping.abort(),
        ["<CR>"] = cmp.mapping.confirm({ select = false }),
        ["<Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_next_item()
            elseif luasnip.expand_or_jumpable() then
                luasnip.expand_or_jump()
            else
                fallback()
            end
        end, { "i", "s" }),
        ["<S-Tab>"] = cmp.mapping(function(fallback)
            if cmp.visible() then
                cmp.select_prev_item()
            elseif luasnip.jumpable(-1) then
                luasnip.jump(-1)
            else
                fallback()
            end
        end, { "i", "s" }),
    }),
    sources = cmp.config.sources({
        { name = "nvim_lsp" },
        { name = "nvim_lsp_signature_help" },
        { name = "luasnip" },
        { name = "path" },
    }, {
        { name = "buffer" },
    }),
    formatting = {
        fields = { "kind", "abbr", "menu" },
        format = function(entry, item)
            item.kind = string.format("%s", kind_icons[item.kind] or item.kind)
            item.menu = ({
                nvim_lsp = "[LSP]",
                nvim_lsp_signature_help = "[Sig]",
                luasnip = "[Snip]",
                buffer = "[Buf]",
                path = "[Path]",
            })[entry.source.name]
            return item
        end,
    },
    experimental = { ghost_text = true },
})

local alpha = require("alpha")
local dashboard = require("alpha.themes.dashboard")
dashboard.section.header.val = {
    "",
    "   P W N B O X",
    "",
    "   n e o v i m",
    "",
}
dashboard.section.header.opts.hl = "Title"
dashboard.section.buttons.val = {
    dashboard.button("f", "  Find file", "<cmd>Telescope find_files<cr>"),
    dashboard.button("r", "  Recent files", "<cmd>Telescope oldfiles<cr>"),
    dashboard.button("g", "  Live grep", "<cmd>Telescope live_grep<cr>"),
    dashboard.button("e", "  File explorer", "<cmd>Neotree toggle<cr>"),
    dashboard.button("s", "  Restore session", [[<cmd>lua require("persistence").load()<cr>]]),
    dashboard.button("n", "  New file", "<cmd>enew<cr>"),
    dashboard.button("q", "  Quit", "<cmd>qa<cr>"),
}
dashboard.section.buttons.opts.hl = "Function"
dashboard.section.footer.val = " "
dashboard.section.footer.opts.hl = "Comment"
alpha.setup(dashboard.config)
