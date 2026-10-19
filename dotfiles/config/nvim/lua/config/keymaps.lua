
local map = vim.keymap.set
local function imap(lhs, rhs, desc)
  map({ "n", "i", "v" }, lhs, rhs, { desc = desc })
end

imap("<C-s>", "<cmd>write<cr>", "Save file")

map("n", "<C-p>", "<cmd>Telescope find_files<cr>", { desc = "Quick open file" })
map("n", "<C-S-p>", "<cmd>Telescope commands<cr>", { desc = "Command palette" })
map("n", "<C-S-f>", "<cmd>Telescope live_grep<cr>", { desc = "Find in files" })
map("n", "<C-f>", "<cmd>Telescope current_buffer_fuzzy_find<cr>", { desc = "Find in file" })

local function toggle_sidebar()
  vim.cmd("Neotree toggle")
end
map("n", "<C-b>", toggle_sidebar, { desc = "Toggle sidebar" })
map("n", "<C-S-e>", toggle_sidebar, { desc = "Toggle sidebar" })

local fullscreen_terminal
local function toggle_terminal()
  if not fullscreen_terminal then
    fullscreen_terminal = require("toggleterm.terminal").Terminal:new({
      id = 99,
      direction = "float",
      float_opts = {
        border = "none",
        width = function() return vim.o.columns end,
        height = function() return vim.o.lines - vim.o.cmdheight end,
        row = 0,
        col = 0,
      },
    })
  end
  fullscreen_terminal:toggle()
end
map({ "n", "t" }, "<C-j>", toggle_terminal, { desc = "Toggle terminal" })
map({ "n", "t" }, "<C-`>", toggle_terminal, { desc = "Toggle terminal" })

map("n", "<C-\\>", "<cmd>vsplit<cr>", { desc = "Split editor right" })
map("n", "<C-S-\\>", "<cmd>split<cr>", { desc = "Split editor down" })

map("n", "<C-h>", "<C-w>h", { desc = "Focus left" })
map("n", "<C-k>", "<C-w>k", { desc = "Focus up" })
map("n", "<C-l>", "<C-w>l", { desc = "Focus right" })
map("n", "<C-Down>", "<C-w>j", { desc = "Focus down" })
map("n", "<C-S-Up>", "<cmd>resize +2<cr>", { desc = "Grow window" })
map("n", "<C-S-Down>", "<cmd>resize -2<cr>", { desc = "Shrink window" })
map("n", "<C-S-Left>", "<cmd>vertical resize -2<cr>", { desc = "Shrink window width" })
map("n", "<C-S-Right>", "<cmd>vertical resize +2<cr>", { desc = "Grow window width" })

map({ "n", "i" }, "<C-Tab>", "<cmd>BufferLineCycleNext<cr>", { desc = "Next editor" })
map({ "n", "i" }, "<C-S-Tab>", "<cmd>BufferLineCyclePrev<cr>", { desc = "Previous editor" })
map("n", "<C-w>", "<cmd>bdelete<cr>", { desc = "Close editor" })

map("n", "<C-a>", "ggVG", { desc = "Select all" })
map("n", "<C-S-k>", "dd", { desc = "Delete line" })
map("n", "<C-CR>", "o<Esc>", { desc = "Insert line below" })
map("n", "<C-S-CR>", "O<Esc>", { desc = "Insert line above" })
map("n", "<C-g>", function()
  local line = tonumber(vim.fn.input("Go to line: "))
  if line then
    vim.api.nvim_win_set_cursor(0, { line, 0 })
  end
end, { desc = "Go to line" })

local function duplicate(dir)
  local s, e
  if vim.fn.mode():match("[vV\22]") then
    vim.cmd("normal! \27")
    s, e = vim.fn.line("'<"), vim.fn.line("'>")
  else
    s, e = vim.fn.line("."), vim.fn.line(".")
  end
  local lines = vim.api.nvim_buf_get_lines(0, s - 1, e, false)
  local at = dir == "down" and e or (s - 1)
  vim.api.nvim_buf_set_lines(0, at, at, false, lines)
  vim.api.nvim_win_set_cursor(0, { dir == "down" and (e + #lines) or (s + #lines - 1), 0 })
end

map("n", "<A-Down>", "<cmd>m .+1<cr>==", { desc = "Move line down" })
map("n", "<A-Up>", "<cmd>m .-2<cr>==", { desc = "Move line up" })
map("v", "<A-Down>", ":m '>+1<cr>gv=gv", { desc = "Move selection down" })
map("v", "<A-Up>", ":m '<-2<cr>gv=gv", { desc = "Move selection up" })
map({ "n", "v" }, "<A-S-Down>", function()
  duplicate("down")
end, { desc = "Duplicate line down" })
map({ "n", "v" }, "<A-S-Up>", function()
  duplicate("up")
end, { desc = "Duplicate line up" })

map("v", "<", "<gv", { desc = "Indent left" })
map("v", ">", ">gv", { desc = "Indent right" })
map("v", "p", '"_dP', { desc = "Paste without yanking" })

local function toggle_comment()
  require("Comment.api").toggle.linewise.current()
end
local function toggle_comment_visual()
  require("Comment.api").toggle.linewise(vim.fn.visualmode())
end
map("n", "<C-/>", toggle_comment, { desc = "Toggle comment" })
map("v", "<C-/>", toggle_comment_visual, { desc = "Toggle comment" })
map("n", "<C-_>", toggle_comment, { desc = "Toggle comment" })
map("v", "<C-_>", toggle_comment_visual, { desc = "Toggle comment" })

map({ "n", "v" }, "<A-S-f>", function()
  require("conform").format({ async = true, lsp_format = "fallback" })
end, { desc = "Format document" })
map("n", "<leader>cl", function()
  require("lint").try_lint()
end, { desc = "Lint buffer" })

map("n", "<Esc>", "<cmd>nohlsearch<cr>", { desc = "Clear search highlight" })

map("n", "-", "<cmd>Oil<cr>", { desc = "Open parent directory" })
map("n", "<leader>ff", "<cmd>Telescope find_files<cr>", { desc = "Find files" })
map("n", "<leader>fg", "<cmd>Telescope live_grep<cr>", { desc = "Live grep" })
map("n", "<leader>fw", "<cmd>Telescope grep_string<cr>", { desc = "Grep word under cursor" })
map("n", "<leader>fb", "<cmd>Telescope buffers<cr>", { desc = "Buffers" })
map("n", "<leader>fr", "<cmd>Telescope oldfiles<cr>", { desc = "Recent files" })
map("n", "<leader>fh", "<cmd>Telescope help_tags<cr>", { desc = "Help tags" })
map("n", "<leader>fk", "<cmd>Telescope keymaps<cr>", { desc = "Keymaps" })
map("n", "<leader>fd", "<cmd>Telescope diagnostics<cr>", { desc = "Diagnostics" })
map("n", "<leader>fs", "<cmd>Telescope lsp_document_symbols<cr>", { desc = "Document symbols" })

map("n", "<leader>gg", function()
  require("gitsigns").toggle_current_line_blame()
end, { desc = "Toggle line blame" })
map("n", "<leader>gb", "<cmd>Telescope git_branches<cr>", { desc = "Branches" })
map("n", "<leader>gc", "<cmd>Telescope git_commits<cr>", { desc = "Commits" })
map("n", "<leader>gs", "<cmd>Telescope git_status<cr>", { desc = "Status" })

local function git_history()
  require("neogit").action("log", "log_all_references", {})()
end
map("n", "<C-S-g>", git_history, { desc = "Git commit history" })
map("n", "<leader>gl", git_history, { desc = "Git commit history" })
map("n", "<leader>gn", "<cmd>Neogit<cr>", { desc = "Git status (Neogit)" })

map("n", "<leader>xx", "<cmd>Trouble diagnostics toggle<cr>", { desc = "Diagnostics" })
map("n", "<leader>xX", "<cmd>Trouble diagnostics toggle filter.buf=0<cr>", { desc = "Buffer diagnostics" })
map("n", "<leader>xs", "<cmd>Trouble symbols toggle<cr>", { desc = "Symbols" })
map("n", "<leader>xl", "<cmd>Trouble lsp toggle<cr>", { desc = "LSP definitions / references" })
map("n", "<leader>xq", "<cmd>Trouble qflist toggle<cr>", { desc = "Quickfix list" })
map("n", "[d", function()
  vim.diagnostic.jump({ count = -1 })
end, { desc = "Previous diagnostic" })
map("n", "]d", function()
  vim.diagnostic.jump({ count = 1 })
end, { desc = "Next diagnostic" })

map("n", "<leader>tt", "<cmd>ToggleTerm direction=float<cr>", { desc = "Floating terminal" })
map("n", "<leader>th", "<cmd>ToggleTerm direction=horizontal<cr>", { desc = "Horizontal terminal" })
map("n", "<leader>tv", "<cmd>ToggleTerm direction=vertical<cr>", { desc = "Vertical terminal" })
map("t", "<Esc><Esc>", "<C-\\><C-n>", { desc = "Terminal normal mode" })

map("n", "<leader>wv", "<cmd>vsplit<cr>", { desc = "Split window right" })
map("n", "<leader>ws", "<cmd>split<cr>", { desc = "Split window down" })
map("n", "<leader>wd", "<cmd>close<cr>", { desc = "Close window" })

map("n", "<leader>bd", "<cmd>bdelete<cr>", { desc = "Close editor" })
map("n", "<leader>bn", "<cmd>enew<cr>", { desc = "New file" })
map("n", "<leader>bo", function()
  local current = vim.api.nvim_get_current_buf()
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if buf ~= current and vim.api.nvim_buf_is_valid(buf) and vim.api.nvim_buf_is_loaded(buf) then
      vim.api.nvim_buf_delete(buf, { force = true })
    end
  end
end, { desc = "Close other editors" })

map("n", "<leader>qs", function()
  require("persistence").load()
end, { desc = "Restore session" })
map("n", "<leader>ql", function()
  require("persistence").load({ last = true })
end, { desc = "Restore last session" })
map("n", "<leader>qd", function()
  require("persistence").stop()
end, { desc = "Stop session recording" })

map("n", "<leader>w", "<cmd>write<cr>", { desc = "Save file" })
map("n", "<leader>q", "<cmd>quit<cr>", { desc = "Quit window" })
map("n", "<leader>Q", "<cmd>qa!<cr>", { desc = "Quit all" })
map("n", "<leader>ul", "<cmd>set list!<cr>", { desc = "Toggle list chars" })
map("n", "<leader>uw", "<cmd>set wrap!<cr>", { desc = "Toggle line wrap" })
map("n", "<leader>ub", "<cmd>BufferLineTogglePin<cr>", { desc = "Pin editor" })
map("n", "<leader>un", function()
  require("notify").dismiss({ silent = true, pending = true })
end, { desc = "Dismiss notifications" })
