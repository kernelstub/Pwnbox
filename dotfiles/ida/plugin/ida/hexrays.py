"""
Pseudocode colours: re-tag Hex-Rays output for the pwnbox theme.

Hex-Rays prints pseudocode with only a handful of IDA colour tags and reuses
each one for unrelated things: keywords, numbers and labels share KEYWORD;
member names, operators and brackets share SYMBOL; function names and globals
share DEMNAME; a declaration such as `int v3` is a single span. A theme can
only colour per tag, so we re-tag every printed line so that each
kind of token gets a tag of its own, which theme.css then colours:

    token                    tag          theme property
    keyword (if, return)     KEYWORD      line-fg-keyword
    number, nullptr          NUMBER       line-fg-numlit-in-insn
    string / char            STRING/CHAR  line-fg-strlit-in-insn / charlit-in-insn
    comment                  REGCMT       line-fg-regular-comment
    variable, member         LOCNAME      line-fg-locvar
    function                 CNAME        line-fg-code-name
    imported function        IMPNAME      line-fg-import-name
    global variable          DNAME        line-fg-regular-data-name
    macro (LODWORD, BYTE1)   MACRO        line-fg-macro
    type                     HIDNAME      line-fg-hidden
    operator (= == + ->)     ASMDIR       line-fg-asm-directive
    delimiter (( ) ; , .)    SYMBOL       line-fg-punctuation
    label (LABEL_12)         ALTOP        line-fg-alt-opnd
    this                     REG          line-fg-register-name
"""

import re
import traceback

import ida_bytes
import ida_funcs
import ida_hexrays
import ida_idaapi
import ida_lines
import ida_nalt
import ida_name
import ida_typeinf

from perf import perf

ON = ida_lines.SCOLOR_ON
OFF = ida_lines.SCOLOR_OFF
ESC = ida_lines.SCOLOR_ESC
INV = ida_lines.SCOLOR_INV
ADDR = ida_lines.SCOLOR_ADDR
ADDR_SIZE = ida_lines.COLOR_ADDR_SIZE

HR_KEYWORD = ida_lines.SCOLOR_KEYWORD
HR_SYMBOL = ida_lines.SCOLOR_SYMBOL
HR_VAR = ida_lines.SCOLOR_LIBNAME
HR_VAR2 = ida_lines.SCOLOR_VOIDOP
HR_STRING = ida_lines.SCOLOR_LOCNAME
HR_COMMENT = ida_lines.SCOLOR_NUMBER
HR_TYPE = ida_lines.SCOLOR_HIDNAME
HR_DECL = ida_lines.SCOLOR_REG
HR_NAMES = (
    ida_lines.SCOLOR_DEMNAME,
    ida_lines.SCOLOR_IMPNAME,
    ida_lines.SCOLOR_CNAME,
    ida_lines.SCOLOR_CODNAME,
    ida_lines.SCOLOR_DNAME,
    ida_lines.SCOLOR_DATNAME,
)
T_KEYWORD = ida_lines.SCOLOR_KEYWORD
T_NUMBER = ida_lines.SCOLOR_NUMBER
T_STRING = ida_lines.SCOLOR_STRING
T_CHAR = ida_lines.SCOLOR_CHAR
T_COMMENT = ida_lines.SCOLOR_REGCMT
T_VARIABLE = ida_lines.SCOLOR_LOCNAME
T_FUNCTION = ida_lines.SCOLOR_CNAME
T_IMPORT = ida_lines.SCOLOR_IMPNAME
T_GLOBAL = ida_lines.SCOLOR_DNAME
T_MACRO = ida_lines.SCOLOR_MACRO
T_TYPE = ida_lines.SCOLOR_HIDNAME
T_OPERATOR = ida_lines.SCOLOR_ASMDIR
T_DELIMITER = ida_lines.SCOLOR_SYMBOL
T_LABEL = ida_lines.SCOLOR_ALTOP
T_BUILTIN = ida_lines.SCOLOR_REG

KEYWORDS = {
    "if", "else", "while", "for", "do", "switch", "case", "default", "break",
    "continue", "return", "goto", "sizeof", "__asm", "try", "catch", "throw",
}
CONSTANTS = {"nullptr", "true", "false", "NULL"}
TYPE_KEYWORDS = {
    "const", "volatile", "struct", "union", "enum", "class", "static",
    "__cdecl", "__stdcall", "__fastcall", "__thiscall", "__usercall",
    "__userpurge", "__pascal", "__vectorcall", "__golang", "__swiftcall",
    "__spoils", "__noreturn", "__hidden", "__return_ptr", "__struct_ptr",
    "__shifted", "__unaligned", "__ptr32", "__ptr64", "__restrict",
    "__far", "__near", "__high", "operator",
}
OPERATORS = {
    "=", "==", "!=", "<", ">", "<=", ">=", "+", "-", "*", "/", "%", "&", "|",
    "^", "~", "!", "&&", "||", "<<", ">>", "+=", "-=", "*=", "/=", "%=", "&=",
    "|=", "^=", "<<=", ">>=", "++", "--", "->", "?",
}

NUMBER_RE = re.compile(
    r"-?(?:0x[0-9A-Fa-f]+|\d+(?:\.\d*)?(?:[eE][+-]?\d+)?)"
    r"(?:u|U|l|L|i64|ui64|LL|uLL|ULL|f|F)*$"
)
IDENT_RE = re.compile(r"[A-Za-z_$~][\w$~]*$")
MACRO_RE = re.compile(r"_*[A-Z][A-Z0-9_]*$")
TYPE_TOKEN_RE = re.compile(r"~?[\w$]+(?:::~?[\w$]+)*|\s+|[^\w\s$~]|~")


def _is_comment(text):
    return text.lstrip().startswith(("//", "/*"))


def _is_function(ea):
    if ida_funcs.get_func(ea) is not None:
        return True
    if ida_bytes.is_code(ida_bytes.get_flags(ea)):
        return True
    tif = ida_typeinf.tinfo_t()
    return ida_nalt.get_tinfo(tif, ea) and (tif.is_func() or tif.is_funcptr())


def _classify_name(tag, name, is_call):
    ea = ida_name.get_name_ea(ida_idaapi.BADADDR, name)
    if ea != ida_idaapi.BADADDR:
        if _is_function(ea):
            return T_IMPORT if tag == ida_lines.SCOLOR_IMPNAME else T_FUNCTION
        return T_GLOBAL
    if MACRO_RE.match(name):
        return T_MACRO
    if not is_call:
        return T_GLOBAL
    return T_IMPORT if tag == ida_lines.SCOLOR_IMPNAME else T_FUNCTION


def _split_type(text, next_text, lvars):
    """Split a type/declaration span into type, keyword and variable pieces."""
    pieces = []
    tokens = TYPE_TOKEN_RE.findall(text)
    for i, tok in enumerate(tokens):
        if tok.isspace():
            pieces.append((None, tok))
        elif tok[0].isalnum() or tok[0] in "_$~":
            following = tokens[i + 1] if i + 1 < len(tokens) else next_text
            if tok == "this":
                pieces.append((T_BUILTIN, tok))
            elif tok in lvars:
                pieces.append((T_VARIABLE, tok))
            elif tok in TYPE_KEYWORDS:
                pieces.append((T_KEYWORD, tok))
            elif following.startswith("("):
                pieces.append((T_FUNCTION, tok))
            else:
                pieces.append((T_TYPE, tok))
        elif tok in ("*", "&"):
            pieces.append((T_OPERATOR, tok))
        else:
            pieces.append((T_DELIMITER, tok))
    return pieces


def _classify(tag, text, next_text, lvars):
    """Return [(new_tag or None, text), ...] for one text run under `tag`."""
    word = text.strip()
    if not word:
        return [(None, text)]
    if tag == HR_COMMENT or _is_comment(text):
        return [(T_COMMENT, text)]

    if tag == HR_KEYWORD:
        if NUMBER_RE.match(word) or word in CONSTANTS:
            return [(T_NUMBER, text)]
        if word.startswith("'"):
            return [(T_CHAR, text)]
        if word in KEYWORDS:
            return [(T_KEYWORD, text)]
        return [(T_LABEL, text)]

    if tag == HR_SYMBOL:
        if IDENT_RE.match(word):
            return [(T_VARIABLE, text)]
        if word in OPERATORS:
            return [(T_OPERATOR, text)]
        return [(T_DELIMITER, text)]

    if tag in (HR_VAR, HR_VAR2):
        return [(T_BUILTIN if word == "this" else T_VARIABLE, text)]

    if tag == HR_STRING:
        return [(T_CHAR if word.startswith("'") else T_STRING, text)]

    if tag in HR_NAMES:
        return [(_classify_name(tag, word, next_text.startswith("(")), text)]

    if tag in (HR_TYPE, HR_DECL):
        return _split_type(text, next_text, lvars)

    return [(None, text)]


def _tokenize(line):
    """Split a tagged line into ("on"|"off"|"raw"|"text", value) tokens."""
    toks = []
    text = []
    i, n = 0, len(line)

    def flush():
        if text:
            toks.append(("text", "".join(text)))
            text.clear()

    while i < n:
        c = line[i]
        if c == ON and i + 1 < n:
            flush()
            if line[i + 1] == ADDR:
                toks.append(("raw", line[i:i + 2 + ADDR_SIZE]))
                i += 2 + ADDR_SIZE
            else:
                toks.append(("on", line[i + 1]))
                i += 2
        elif c == OFF and i + 1 < n:
            flush()
            toks.append(("off", line[i + 1]))
            i += 2
        elif c == ESC and i + 1 < n:
            flush()
            toks.append(("raw", line[i:i + 2]))
            i += 2
        elif c == INV:
            flush()
            toks.append(("raw", c))
            i += 1
        else:
            text.append(c)
            i += 1
    flush()
    return toks


def retag_line(line, lvars):
    toks = _tokenize(line)

    next_text = [""] * len(toks)
    following = ""
    for i in range(len(toks) - 1, -1, -1):
        next_text[i] = following
        kind, val = toks[i]
        if kind == "text" and val.strip():
            following = val.lstrip()

    out = []
    stack = []
    in_comment = False
    for i, (kind, val) in enumerate(toks):
        if kind == "on":
            stack.append(val)
            out.append(ON + val)
        elif kind == "off":
            if stack:
                stack.pop()
            out.append(OFF + val)
        elif kind == "raw":
            out.append(val)
        else:
            tag = stack[-1] if stack else None
            if not in_comment and _is_comment(val):
                in_comment = True
            if in_comment:
                pieces = [(T_COMMENT, val)]
            else:
                pieces = _classify(tag, val, next_text[i], lvars)
            for new_tag, piece in pieces:
                if new_tag is None or new_tag == tag:
                    out.append(piece)
                else:
                    out.append(ON + new_tag + piece + OFF + new_tag)
    return "".join(out)


def retag_cfunc(cfunc):
    lvars = {lv.name for lv in cfunc.get_lvars()}
    for sl in cfunc.get_pseudocode():
        sl.line = retag_line(sl.line, lvars)


class _HexraysHooks(ida_hexrays.Hexrays_Hooks):
    def func_printed(self, cfunc):
        try:
            with perf.measure("pseudocode: retag"):
                retag_cfunc(cfunc)
        except Exception:
            traceback.print_exc()
        return 0


class Retagger:
    """Owns the Hex-Rays hooks. The decompiler is only available once a
    database is open, so start() is retried on every database open."""

    def __init__(self):
        self.hooks = None

    def start(self):
        if self.hooks is None and ida_hexrays.init_hexrays_plugin():
            self.hooks = _HexraysHooks()
            self.hooks.hook()

    def stop(self):
        if self.hooks is not None:
            self.hooks.unhook()
            self.hooks = None
