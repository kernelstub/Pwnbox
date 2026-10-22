
local opt = vim.opt

vim.g.mapleader = " "
vim.g.maplocalleader = "\\"

opt.termguicolors = true
opt.background = "dark"
opt.number = true
opt.relativenumber = false
opt.numberwidth = 4
opt.signcolumn = "yes"
opt.cursorline = true
opt.cursorlineopt = "number,line"
opt.showmode = false

opt.guicursor = "n-v-c-sm:ver25,i-ci-ve:ver25,r-cr:ver25,o:ver25,t:ver25,a:blinkwait700-blinkon400-blinkoff250"

opt.guifont = "IoskeleyMono Nerd Font:h12"
opt.ruler = true
opt.laststatus = 3
opt.cmdheight = 1
opt.pumheight = 12
opt.pumblend = 0
opt.winblend = 0
opt.winborder = "rounded"
opt.fillchars = {
  eob = " ",
  fold = " ",
  foldopen = "▾",
  foldclose = "▸",
  foldsep = "│",
  diff = "╱",
}
opt.list = false
opt.listchars = { tab = "│ ", trail = "·", nbsp = "·", extends = "›", precedes = "‹" }
opt.wrap = false
opt.linebreak = true
opt.scrolloff = 8
opt.sidescrolloff = 8
opt.splitright = true
opt.splitbelow = true
opt.equalalways = false
opt.winminwidth = 5
opt.showtabline = 0

opt.expandtab = true
opt.shiftwidth = 2
opt.tabstop = 2
opt.softtabstop = 2
opt.smartindent = true
opt.breakindent = true
opt.autoindent = true
opt.copyindent = true
opt.shiftround = true
opt.undofile = true
opt.undolevels = 10000
opt.undoreload = 10000
opt.swapfile = false
opt.backup = false
opt.writebackup = false
opt.updatetime = 250
opt.timeout = true
opt.timeoutlen = 400
opt.ttimeoutlen = 10
opt.confirm = true
opt.hidden = true
opt.errorbells = false
opt.mouse = "a"
opt.mousemoveevent = true
opt.clipboard = "unnamedplus"
opt.jumpoptions = "view"
opt.report = 0

opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true
opt.inccommand = "split"
opt.grepprg = "rg --vimgrep --smart-case --hidden --glob '!.git/*'"
opt.grepformat = "%f:%l:%c:%m"

opt.completeopt = { "menu", "menuone", "noselect", "noinsert" }
opt.complete = { ".", "w", "b", "u", "t", "i" }
opt.wildmode = "longest:full,full"
opt.wildignore:append({
  "*.o",
  "*.obj",
  "*.pyc",
  "*.class",
  "*.jar",
  "*.bin",
  "*.exe",
  "*.so",
  "*.dll",
  "*/node_modules/*",
  "*/.git/*",
  "*/dist/*",
  "*/target/*",
})

opt.foldmethod = "manual"
opt.foldlevel = 99
opt.foldlevelstart = 99
opt.foldenable = true

opt.formatoptions = "jqlnt"
opt.textwidth = 0
opt.spell = false
opt.spelllang = { "en" }

opt.sessionoptions = {
  "buffers",
  "curdir",
  "tabpages",
  "winsize",
  "help",
  "globals",
  "skiprtp",
  "folds",
}

opt.shortmess:append("cC")
opt.diffopt:append("linematch:60")
opt.virtualedit = "block"
opt.selection = "inclusive"
opt.synmaxcol = 300
