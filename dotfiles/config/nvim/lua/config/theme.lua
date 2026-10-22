
local M = {}

local palette_path = vim.fn.expand("~/.cache/pwnbox/theme/nvim-palette.lua")

local raw_default = {
  bg = "#080808",
  fg = "#cccccc",
  cursor = "#cccccc",
  accent = "#252525",
  color0 = "#171717",
  color1 = "#6b6b6b",
  color2 = "#c4c4c4",
  color3 = "#999999",
  color4 = "#999999",
  color5 = "#717171",
  color6 = "#8a8a8a",
  color7 = "#cccccc",
  color8 = "#353535",
  color9 = "#6b6b6b",
  color10 = "#c4c4c4",
  color11 = "#999999",
  color12 = "#999999",
  color13 = "#717171",
  color14 = "#8a8a8a",
  color15 = "#ffffff",
}

local function hex_to_rgb(hex)
  hex = tostring(hex):gsub("#", "")
  return tonumber(hex:sub(1, 2), 16), tonumber(hex:sub(3, 4), 16), tonumber(hex:sub(5, 6), 16)
end

local function rgb_to_hex(r, g, b)
  return string.format("#%02x%02x%02x", r, g, b)
end

local function mix(a, b, amount)
  local ar, ag, ab = hex_to_rgb(a)
  local br, bg, bb = hex_to_rgb(b)
  return rgb_to_hex(
    math.floor(ar + (br - ar) * amount + 0.5),
    math.floor(ag + (bg - ag) * amount + 0.5),
    math.floor(ab + (bb - ab) * amount + 0.5)
  )
end

local function luminance(hex)
  local r, g, b = hex_to_rgb(hex)
  return (0.2126 * r + 0.7152 * g + 0.0722 * b) / 255
end

local function build_palette(raw)
  local bg, fg = raw.bg, raw.fg
  local extreme = luminance(bg) < 0.5 and "#ffffff" or "#000000"
  return {
    bg = bg,
    bg_alt = mix(bg, fg, 0.04),
    bg_hl = mix(bg, fg, 0.07),
    bg_sel = mix(bg, fg, 0.15),
    border = mix(bg, fg, 0.15),
    border_hi = mix(bg, fg, 0.23),
    grey = mix(bg, fg, 0.31),
    dim = mix(bg, fg, 0.50),
    muted = mix(bg, fg, 0.66),
    fg = fg,
    bright = mix(fg, extreme, 0.51),
    white = extreme,
    accent = raw.accent or mix(bg, fg, 0.15),
    red = raw.color1,
    green = raw.color2,
    yellow = raw.color3,
    blue = raw.color4,
    mauve = raw.color5,
    cyan = raw.color6,
    bright_black = raw.color8,
    bright_red = raw.color9,
    bright_green = raw.color10,
    bright_yellow = raw.color11,
    bright_blue = raw.color12,
    bright_magenta = raw.color13,
    bright_cyan = raw.color14,
    term = {
      raw.color0,
      raw.color1,
      raw.color2,
      raw.color3,
      raw.color4,
      raw.color5,
      raw.color6,
      raw.color7,
      raw.color8,
      raw.color9,
      raw.color10,
      raw.color11,
      raw.color12,
      raw.color13,
      raw.color14,
      raw.color15,
    },
  }
end

local function read_raw()
  local raw = vim.deepcopy(raw_default)
  local chunk = loadfile(palette_path)
  if chunk then
    local ok, generated = pcall(chunk)
    if ok and type(generated) == "table" then
      for k, v in pairs(generated) do
        if type(v) == "string" then
          raw[k] = v
        end
      end
    end
  end
  return raw
end

M.palette = build_palette(raw_default)

function M.load()
  local fresh = build_palette(read_raw())
  for k, v in pairs(fresh) do
    M.palette[k] = v
  end
  return M.palette
end

M._reload_hooks = {}

function M.on_reload(fn)
  table.insert(M._reload_hooks, fn)
end

local watching = false
function M.watch()
  if watching then
    return
  end
  watching = true
  local uv = vim.uv or vim.loop
  local function signature()
    return table.concat(vim.fn.readfile(palette_path), "\n")
  end
  local last = signature()
  local timer = uv.new_timer()
  timer:start(
    0,
    1500,
    vim.schedule_wrap(function()
      local sig = signature()
      if sig ~= last then
        last = sig
        M.setup()
        for _, fn in ipairs(M._reload_hooks) do
          pcall(fn, M.palette)
        end
        if vim.api.nvim_get_mode().mode ~= "c" then
          vim.cmd("redraw!")
        end
      end
    end)
  )
  M._timer = timer
end

function M.setup()
  M.load()
  local p = M.palette
  local function hl(group, opts)
    vim.api.nvim_set_hl(0, group, opts)
  end

  vim.cmd("highlight clear")
  if vim.fn.exists("syntax_on") == 1 then
    vim.cmd("syntax reset")
  end
  vim.o.background = luminance(p.bg) < 0.5 and "dark" or "light"
  vim.g.colors_name = "pwnbox"

  hl("Normal", { fg = p.fg, bg = p.bg })
  hl("NormalNC", { fg = p.fg, bg = p.bg })
  hl("NormalFloat", { fg = p.fg, bg = p.bg_alt })
  hl("FloatBorder", { fg = p.border_hi, bg = p.bg_alt })
  hl("FloatTitle", { fg = p.bright, bg = p.bg_alt, bold = true })
  hl("FloatShadow", { bg = p.bg })
  hl("FloatShadowThrough", { bg = p.bg })
  hl("ColorColumn", { bg = p.bg_alt })
  hl("Conceal", { fg = p.grey })
  hl("Cursor", { fg = p.bg, bg = p.white })
  hl("lCursor", { fg = p.bg, bg = p.white })
  hl("CursorIM", { fg = p.bg, bg = p.white })
  hl("TermCursor", { fg = p.bg, bg = p.white })
  hl("TermCursorNC", { fg = p.bg, bg = p.grey })
  hl("CursorColumn", { bg = p.bg_alt })
  hl("CursorLine", { bg = p.bg_alt })
  hl("CursorLineNr", { fg = p.white, bold = true })
  hl("LineNr", { fg = p.grey })
  hl("LineNrAbove", { fg = p.grey })
  hl("LineNrBelow", { fg = p.grey })
  hl("SignColumn", { fg = p.grey, bg = p.bg })
  hl("FoldColumn", { fg = p.grey, bg = p.bg })
  hl("Folded", { fg = p.muted, bg = p.bg_alt })
  hl("EndOfBuffer", { fg = p.bg, bg = p.bg })
  hl("NonText", { fg = p.border })
  hl("Whitespace", { fg = p.border })
  hl("SpecialKey", { fg = p.grey })
  hl("MatchParen", { fg = p.yellow, bold = true, underline = true })
  hl("Directory", { fg = p.blue, bold = true })
  hl("Title", { fg = p.white, bold = true })
  hl("ErrorMsg", { fg = p.red, bold = true })
  hl("WarningMsg", { fg = p.yellow })
  hl("ModeMsg", { fg = p.blue, bold = true })
  hl("MoreMsg", { fg = p.green })
  hl("Question", { fg = p.green })
  hl("MsgArea", { fg = p.fg, bg = p.bg })
  hl("MsgSeparator", { fg = p.border, bg = p.bg })
  hl("WinBar", { fg = p.fg, bg = p.bg, bold = true })
  hl("WinBarNC", { fg = p.dim, bg = p.bg })
  hl("WinSeparator", { fg = p.border, bg = p.bg })
  hl("VertSplit", { fg = p.border, bg = p.bg })

  hl("Visual", { fg = p.white, bg = p.bg_sel })
  hl("VisualNOS", { fg = p.white, bg = p.bg_sel })
  hl("Search", { fg = p.bg, bg = p.bright })
  hl("IncSearch", { fg = p.bg, bg = p.white, bold = true })
  hl("CurSearch", { fg = p.bg, bg = p.white, bold = true })
  hl("Substitute", { fg = p.bg, bg = p.muted })

  hl("Pmenu", { fg = p.fg, bg = p.bg_alt })
  hl("PmenuSel", { fg = p.bg, bg = p.bright, bold = true })
  hl("PmenuKind", { fg = p.muted, bg = p.bg_alt })
  hl("PmenuKindSel", { fg = p.bg, bg = p.bright })
  hl("PmenuExtra", { fg = p.dim, bg = p.bg_alt })
  hl("PmenuExtraSel", { fg = p.bg, bg = p.bright })
  hl("PmenuSbar", { bg = p.border })
  hl("PmenuThumb", { bg = p.grey })
  hl("WildMenu", { fg = p.bg, bg = p.bright })

  hl("StatusLine", { fg = p.fg, bg = p.bg_alt })
  hl("StatusLineNC", { fg = p.dim, bg = p.bg })
  hl("TabLine", { fg = p.dim, bg = p.bg })
  hl("TabLineFill", { fg = p.dim, bg = p.bg })
  hl("TabLineSel", { fg = p.white, bg = p.bg, bold = true })

  hl("Comment", { fg = p.bright_black, italic = true })
  hl("Constant", { fg = p.yellow })
  hl("String", { fg = p.green })
  hl("Character", { fg = p.green })
  hl("Number", { fg = p.yellow })
  hl("Float", { fg = p.yellow })
  hl("Boolean", { fg = p.yellow, bold = true })
  hl("Identifier", { fg = p.fg })
  hl("Function", { fg = p.blue })
  hl("Statement", { fg = p.mauve, bold = true })
  hl("Conditional", { fg = p.mauve, bold = true })
  hl("Repeat", { fg = p.mauve, bold = true })
  hl("Label", { fg = p.yellow })
  hl("Operator", { fg = p.cyan })
  hl("Keyword", { fg = p.mauve, bold = true })
  hl("Exception", { fg = p.mauve, bold = true })
  hl("PreProc", { fg = p.mauve })
  hl("Include", { fg = p.mauve, bold = true })
  hl("Define", { fg = p.mauve })
  hl("Macro", { fg = p.cyan })
  hl("PreCondit", { fg = p.mauve })
  hl("Type", { fg = p.cyan })
  hl("StorageClass", { fg = p.cyan, bold = true })
  hl("Structure", { fg = p.cyan })
  hl("Typedef", { fg = p.cyan })
  hl("Special", { fg = p.cyan })
  hl("SpecialChar", { fg = p.cyan })
  hl("Tag", { fg = p.blue })
  hl("Delimiter", { fg = p.muted })
  hl("SpecialComment", { fg = p.bright_black, italic = true })
  hl("Debug", { fg = p.yellow })
  hl("Underlined", { underline = true })
  hl("Ignore", { fg = p.grey })
  hl("Error", { fg = p.red, bold = true })
  hl("Todo", { fg = p.bg, bg = p.yellow, bold = true })

  hl("DiagnosticError", { fg = p.red, bold = true })
  hl("DiagnosticWarn", { fg = p.yellow })
  hl("DiagnosticInfo", { fg = p.blue })
  hl("DiagnosticHint", { fg = p.cyan })
  hl("DiagnosticOk", { fg = p.green })
  hl("DiagnosticVirtualTextError", { fg = p.red, italic = true })
  hl("DiagnosticVirtualTextWarn", { fg = p.yellow, italic = true })
  hl("DiagnosticVirtualTextInfo", { fg = p.blue, italic = true })
  hl("DiagnosticVirtualTextHint", { fg = p.cyan, italic = true })
  hl("DiagnosticUnderlineError", { undercurl = true, sp = p.red })
  hl("DiagnosticUnderlineWarn", { undercurl = true, sp = p.yellow })
  hl("DiagnosticUnderlineInfo", { undercurl = true, sp = p.blue })
  hl("DiagnosticUnderlineHint", { undercurl = true, sp = p.cyan })
  hl("DiagnosticFloatingError", { fg = p.red })
  hl("DiagnosticFloatingWarn", { fg = p.yellow })
  hl("DiagnosticFloatingInfo", { fg = p.blue })
  hl("DiagnosticFloatingHint", { fg = p.cyan })

  hl("DiffAdd", { fg = p.green, bg = mix(p.bg, p.green, 0.12) })
  hl("DiffChange", { fg = p.yellow, bg = mix(p.bg, p.yellow, 0.12) })
  hl("DiffDelete", { fg = p.red, bg = mix(p.bg, p.red, 0.10) })
  hl("DiffText", { fg = p.bright, bg = mix(p.bg, p.blue, 0.28), bold = true })
  hl("Added", { fg = p.green })
  hl("Changed", { fg = p.yellow })
  hl("Removed", { fg = p.red })

  local links = {
    ["@comment"] = "Comment",
    ["@error"] = "Error",
    ["@none"] = "Normal",
    ["@preproc"] = "PreProc",
    ["@define"] = "Define",
    ["@operator"] = "Operator",
    ["@punctuation"] = "Delimiter",
    ["@punctuation.delimiter"] = "Delimiter",
    ["@punctuation.bracket"] = "Delimiter",
    ["@punctuation.special"] = "Special",
    ["@string"] = "String",
    ["@string.regex"] = "SpecialChar",
    ["@string.escape"] = "SpecialChar",
    ["@string.special"] = "SpecialChar",
    ["@character"] = "Character",
    ["@character.special"] = "SpecialChar",
    ["@boolean"] = "Boolean",
    ["@number"] = "Number",
    ["@number.float"] = "Float",
    ["@float"] = "Float",
    ["@function"] = "Function",
    ["@function.builtin"] = "Special",
    ["@function.call"] = "Function",
    ["@function.macro"] = "Macro",
    ["@method"] = "Function",
    ["@method.call"] = "Function",
    ["@constructor"] = "Special",
    ["@parameter"] = "Identifier",
    ["@keyword"] = "Keyword",
    ["@keyword.function"] = "Keyword",
    ["@keyword.operator"] = "Operator",
    ["@keyword.return"] = "Keyword",
    ["@keyword.conditional"] = "Conditional",
    ["@keyword.repeat"] = "Repeat",
    ["@keyword.exception"] = "Exception",
    ["@keyword.import"] = "Include",
    ["@conditional"] = "Conditional",
    ["@repeat"] = "Repeat",
    ["@debug"] = "Debug",
    ["@label"] = "Label",
    ["@include"] = "Include",
    ["@exception"] = "Exception",
    ["@type"] = "Type",
    ["@type.builtin"] = "Type",
    ["@type.definition"] = "Typedef",
    ["@type.qualifier"] = "Keyword",
    ["@storageclass"] = "StorageClass",
    ["@attribute"] = "PreProc",
    ["@field"] = "Identifier",
    ["@property"] = "Identifier",
    ["@variable"] = "Identifier",
    ["@variable.builtin"] = "Special",
    ["@variable.parameter"] = "Identifier",
    ["@variable.member"] = "Identifier",
    ["@constant"] = "Constant",
    ["@constant.builtin"] = "Constant",
    ["@constant.macro"] = "Macro",
    ["@module"] = "Identifier",
    ["@namespace"] = "Identifier",
    ["@symbol"] = "Identifier",
    ["@text"] = "Normal",
    ["@text.title"] = "Title",
    ["@text.literal"] = "String",
    ["@text.uri"] = "Underlined",
    ["@text.underline"] = "Underlined",
    ["@text.todo"] = "Todo",
    ["@text.note"] = "Special",
    ["@text.warning"] = "WarningMsg",
    ["@text.danger"] = "ErrorMsg",
    ["@text.diff.add"] = "DiffAdd",
    ["@text.diff.delete"] = "DiffDelete",
    ["@text.reference"] = "Identifier",
    ["@text.emphasis"] = { italic = true },
    ["@text.strong"] = { bold = true },
    ["@tag"] = "Tag",
    ["@tag.attribute"] = "Identifier",
    ["@tag.delimiter"] = "Delimiter",
    ["@markup"] = "Normal",
    ["@markup.strong"] = { bold = true },
    ["@markup.emphasis"] = { italic = true },
    ["@markup.strikethrough"] = { strikethrough = true },
    ["@markup.underline"] = { underline = true },
    ["@markup.heading"] = "Title",
    ["@markup.raw"] = "String",
    ["@markup.link"] = "Underlined",
    ["@markup.link.url"] = "Underlined",
    ["@markup.list"] = "Special",
  }
  for group, target in pairs(links) do
    if type(target) == "table" then
      hl(group, target)
    else
      hl(group, { link = target })
    end
  end

  hl("TreesitterContext", { bg = p.bg_alt })
  hl("TreesitterContextLineNumber", { fg = p.grey, bg = p.bg_alt })

  hl("LspReferenceText", { bg = p.bg_sel })
  hl("LspReferenceRead", { bg = p.bg_sel })
  hl("LspReferenceWrite", { bg = p.bg_sel, underline = true })
  hl("LspSignatureActiveParameter", { fg = p.white, bold = true })
  hl("LspCodeLens", { fg = p.dim })

  hl("GitSignsAdd", { fg = p.green })
  hl("GitSignsChange", { fg = p.yellow })
  hl("GitSignsDelete", { fg = p.red })
  hl("GitSignsAddNr", { fg = p.green })
  hl("GitSignsChangeNr", { fg = p.yellow })
  hl("GitSignsDeleteNr", { fg = p.red })
  hl("GitSignsAddLn", { bg = mix(p.bg, p.green, 0.10) })
  hl("GitSignsChangeLn", { bg = mix(p.bg, p.yellow, 0.10) })
  hl("GitSignsCurrentLineBlame", { fg = p.bright_black, italic = true })

  hl("IblIndent", { fg = p.border })
  hl("IblScope", { fg = p.grey })
  hl("IblWhitespace", { fg = p.border })

  hl("WhichKey", { fg = p.blue, bold = true })
  hl("WhichKeyGroup", { fg = p.mauve })
  hl("WhichKeyDesc", { fg = p.fg })
  hl("WhichKeySeparator", { fg = p.grey })
  hl("WhichKeyFloat", { bg = p.bg_alt })
  hl("WhichKeyBorder", { fg = p.border_hi, bg = p.bg_alt })
  hl("WhichKeyValue", { fg = p.dim })

  hl("NotifyBackground", { bg = p.bg_alt })
  hl("NotifyERRORBorder", { fg = p.red })
  hl("NotifyWARNBorder", { fg = p.yellow })
  hl("NotifyINFOBorder", { fg = p.blue })
  hl("NotifyDEBUGBorder", { fg = p.bright_black })
  hl("NotifyTRACEBorder", { fg = p.bright_black })
  hl("NotifyERRORIcon", { fg = p.red })
  hl("NotifyWARNIcon", { fg = p.yellow })
  hl("NotifyINFOIcon", { fg = p.blue })
  hl("NotifyDEBUGIcon", { fg = p.bright_black })
  hl("NotifyTRACEIcon", { fg = p.bright_black })
  hl("NotifyERRORTitle", { fg = p.red })
  hl("NotifyWARNTitle", { fg = p.yellow })
  hl("NotifyINFOTitle", { fg = p.blue })
  hl("NotifyDEBUGTitle", { fg = p.bright_black })
  hl("NotifyTRACETitle", { fg = p.bright_black })
  hl("NotifyERRORBody", { fg = p.fg })
  hl("NotifyWARNBody", { fg = p.fg })
  hl("NotifyINFOBody", { fg = p.fg })
  hl("NotifyDEBUGBody", { fg = p.fg })
  hl("NotifyTRACEBody", { fg = p.fg })

  hl("BufferLineFill", { bg = p.bg })
  hl("BufferLineBackground", { fg = p.dim, bg = p.bg })
  hl("BufferLineBufferVisible", { fg = p.muted, bg = p.bg })
  hl("BufferLineBufferSelected", { fg = p.white, bg = p.bg, bold = true })
  hl("BufferLineSeparator", { fg = p.border, bg = p.bg })
  hl("BufferLineSeparatorVisible", { fg = p.border, bg = p.bg })
  hl("BufferLineSeparatorSelected", { fg = p.border, bg = p.bg })
  hl("BufferLineCloseButton", { fg = p.dim, bg = p.bg })
  hl("BufferLineCloseButtonVisible", { fg = p.dim, bg = p.bg })
  hl("BufferLineCloseButtonSelected", { fg = p.white, bg = p.bg })
  hl("BufferLineIndicatorSelected", { fg = p.white, bg = p.bg })
  hl("BufferLineModified", { fg = p.yellow, bg = p.bg })
  hl("BufferLineModifiedSelected", { fg = p.yellow, bg = p.bg })

  hl("DevIconDefault", { fg = p.muted })

  hl("NeoTreeNormal", { fg = p.fg, bg = p.bg })
  hl("NeoTreeNormalNC", { fg = p.fg, bg = p.bg })
  hl("NeoTreeDirectoryName", { fg = p.blue, bold = true })
  hl("NeoTreeDirectoryIcon", { fg = p.blue })
  hl("NeoTreeFileIcon", { fg = p.muted })
  hl("NeoTreeFileName", { fg = p.fg })
  hl("NeoTreeFileNameOpened", { fg = p.white, bold = true })
  hl("NeoTreeIndentMarker", { fg = p.grey })
  hl("NeoTreeExpander", { fg = p.grey })
  hl("NeoTreeDotfile", { fg = p.dim })
  hl("NeoTreeHiddenByName", { fg = p.dim })
  hl("NeoTreeIgnored", { fg = p.dim })
  hl("NeoTreeModified", { fg = p.yellow })
  hl("NeoTreeGitAdded", { fg = p.green })
  hl("NeoTreeGitModified", { fg = p.yellow })
  hl("NeoTreeGitDeleted", { fg = p.red })
  hl("NeoTreeGitRenamed", { fg = p.cyan })
  hl("NeoTreeGitStaged", { fg = p.green })
  hl("NeoTreeGitUnstaged", { fg = p.yellow })
  hl("NeoTreeGitUntracked", { fg = p.dim, italic = true })
  hl("NeoTreeGitConflict", { fg = p.red, bold = true, italic = true })
  hl("NeoTreeGitIgnored", { fg = p.dim })
  hl("NeoTreeCursorLine", { bg = p.bg_alt })
  hl("NeoTreeWinSeparator", { fg = p.border, bg = p.bg })
  hl("NeoTreeEndOfBuffer", { fg = p.bg, bg = p.bg })
  hl("NeoTreeTitleBar", { fg = p.bright, bg = p.bg_alt, bold = true })

  hl("CmpDocumentation", { fg = p.fg, bg = p.bg_alt })
  hl("CmpDocumentationBorder", { fg = p.border_hi, bg = p.bg_alt })
  hl("CmpItemAbbr", { fg = p.fg })
  hl("CmpItemAbbrDeprecated", { fg = p.grey, strikethrough = true })
  hl("CmpItemAbbrMatch", { fg = p.white, bold = true })
  hl("CmpItemAbbrMatchFuzzy", { fg = p.blue, bold = true })
  hl("CmpItemMenu", { fg = p.dim, italic = true })
  hl("CmpItemKind", { fg = p.muted })
  hl("CmpItemKindText", { fg = p.fg })
  hl("CmpItemKindFunction", { fg = p.blue })
  hl("CmpItemKindMethod", { fg = p.blue })
  hl("CmpItemKindVariable", { fg = p.fg })
  hl("CmpItemKindKeyword", { fg = p.mauve })
  hl("CmpItemKindSnippet", { fg = p.cyan })
  hl("CmpGhostText", { fg = p.grey, italic = true })

  for i, color in ipairs(p.term) do
    vim.g["terminal_color_" .. (i - 1)] = color
  end

  M.watch()
end

return M
