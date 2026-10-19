
local augroup = function(name)
  return vim.api.nvim_create_augroup("pwnbox_" .. name, { clear = true })
end

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("treesitter"),
  callback = function(args)
    local ok = pcall(vim.treesitter.start, args.buf)
    if ok then
      vim.bo[args.buf].indentexpr = "v:lua.require'nvim-treesitter'.indentexpr()"
    end
  end,
})

vim.api.nvim_create_autocmd("TextYankPost", {
  group = augroup("yank"),
  callback = function()
    vim.hl.on_yank({ higroup = "Visual", timeout = 150 })
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = augroup("last_cursor"),
  callback = function()
    local mark = vim.api.nvim_buf_get_mark(0, '"')
    local lines = vim.api.nvim_buf_line_count(0)
    if mark[1] > 0 and mark[1] <= lines then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd("VimResized", {
  group = augroup("resize"),
  command = "tabdo wincmd =",
})

vim.api.nvim_create_autocmd("FileType", {
  group = augroup("close_with_q"),
  pattern = { "help", "man", "qf", "lspinfo", "checkhealth", "notify" },
  callback = function(args)
    vim.keymap.set("n", "q", "<cmd>close<cr>", { buffer = args.buf, desc = "Close window" })
  end,
})
