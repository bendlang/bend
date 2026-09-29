#!/usr/bin/env python3
"""Prepare explicit lexical UTF16 cursors and parser construction ranges."""
from pathlib import Path
import difflib, hashlib, json, shutil
ROOT=Path(__file__).resolve().parents[4]
BASE=ROOT/'selfhost/build/phase16/spans-shared-migration-01/project'
OUT=ROOT/'selfhost/build/phase16/parser-span-source-01'
OUT.mkdir();shutil.copytree(BASE,OUT/'project');P=OUT/'project/src'
def change(file,old,new):
 p=P/file;s=p.read_text();assert s.count(old)==1,(file,old,s.count(old));p.write_text(s.replace(old,new))
p=P/'front/lexer.bend';s=p.read_text().replace('f_kind: U32}', 'f_kind: U32, begin: U32, end: U32, previousEnd: U32}').replace('FToken{t, l, c, k}', 'FToken{t, l, c, k, begin, end, previousEnd}')
a=s.index('@unsafe\ndef f_lex_scanned(');b=s.index('@unsafe\ndef f_three(s):',a)
s=s[:a]+r'''# Zero disables cursor metadata and preserves the legacy token list.
@unsafe
def f_cursor_add(+offset: U32, +size: U32) -> U32:
  f_choose(U32, U32.is_eq(offset, 0), u => 0, u => U32.add(offset, size))

@unsafe
def f_begin(+ts: List<&2,FToken>) -> U32:
  match ts:
    case Nil{}: 0
    case Con{FToken{text, line, column, kind, begin, end, previousEnd}, rest}: begin

@unsafe
def f_end(+ts: List<&2,FToken>) -> U32:
  match ts:
    case Nil{}: 0
    case Con{FToken{text, line, column, kind, begin, end, previousEnd}, rest}: end

@unsafe
def f_previous_end(+ts: List<&2,FToken>) -> U32:
  match ts:
    case Nil{}: 0
    case Con{FToken{text, line, column, kind, begin, end, previousEnd}, rest}: previousEnd

@unsafe
def f_lex_scanned(
  +sc: FScanned, +l: U32, +c: U32, +d: U32, +k: U32,
  +acc: List<&2,FToken>, +offset: U32, +previous: U32,
) -> List<&2,FToken>:
  match sc:
    case FScanned{word, rest, size}:
      +end = f_cursor_add(offset, f_choose(U32, U32.is_eq(offset, 0), u => 0, u => dg_width(word)))
      f_choose(List<&2,FToken>, U32.is_eq(size, 0),
        u => List.reverse(&2, FToken, Con{FToken{"unterminated string", l, c, 3, offset, offset, previous}, acc}),
        u => f_choose(List<&2,FToken>, U32.is_eq(k, 2),
          u => f_lex_quote_end(word, rest, l, c, d, Con{FToken{word, l, c, k, offset, end, previous}, acc}, end),
          u => f_lex_cursor(rest, l, U32.add(c, size), d, Con{FToken{word, l, c, k, offset, end, previous}, acc}, end, end)))

# Preserve legacy physical columns while indexed cursors count UTF16 units.
@unsafe
def f_lex_quote_end(
  +word: String, +rest: String, +line: U32, +column: U32, +depth: U32,
  +tokens: List<&2,FToken>, +end: U32,
) -> List<&2,FToken>:
  match word:
    case SNil{}: f_lex_cursor(rest, line, column, depth, tokens, end, end)
    case SCon{head, tail}: f_choose(List<&2,FToken>, Char.is_eq(head, '\n'), u => f_lex_quote_end(tail, rest, U32.add(line, 1), 0, depth, tokens, end), u => f_lex_quote_end(tail, rest, line, U32.add(column, 1), depth, tokens, end))

@unsafe
def f_lex_symbol(
  +s: String, +l: U32, +c: U32, +d: U32,
  +acc: List<&2,FToken>, +offset: U32, +previous: U32,
) -> List<&2,FToken>:
  f_choose(List<&2,FToken>, f_pair_op(f_two(s)) && Bool.not(f_eq(f_two(s), "++") && String.ends_with(f_tx(acc), "n") && U32.is_eq(c, U32.add(f_col(acc), U32.from_nat(String.length(f_tx(acc)))))),
    u => f_lex_cursor(f_tail(f_tail(s)), l, U32.add(c, 2), d, Con{FToken{f_choose(String, f_eq(f_two(s), ">>") && U32.is_gt(c, U32.add(f_col(acc), U32.from_nat(String.length(f_tx(acc))))), u => ">>op", u => f_two(s)), l, c, 0, offset, f_cursor_add(offset, 2), previous}, acc}, f_cursor_add(offset, 2), f_cursor_add(offset, 2)),
    u => f_lex_cursor(f_tail(s), l, U32.add(c, 1),
      f_choose(U32, f_ascii_char_eq(f_head(s), '(') || f_ascii_char_eq(f_head(s), '[') || f_ascii_char_eq(f_head(s), '{'),
        u => U32.add(d, 1),
        u => f_choose(U32, f_ascii_char_eq(f_head(s), ')') || f_ascii_char_eq(f_head(s), ']') || f_ascii_char_eq(f_head(s), '}'), u => U32.sub(d, 1), u => d)),
      Con{FToken{f_symbol_text(s, c, acc), l, c, 0, offset, f_cursor_add(offset, dg_units(f_head(s))), previous}, acc}, f_cursor_add(offset, dg_units(f_head(s))), f_cursor_add(offset, dg_units(f_head(s)))))

@unsafe
def f_lex(s, l, c, d, acc):
  f_lex_cursor(s, l, c, d, acc, 0, 0)

@unsafe
def f_lex_indexed(+start: U32, +source: String) -> List<&2,FToken>:
  f_lex_cursor(source, 1, 0, 0, Nil{}, start, start)

# A comment advances source position but retains historical token columns.
@unsafe
def f_lex_comment(+s: String, +l: U32, +c: U32, +d: U32, +acc: List<&2,FToken>, +offset: U32, +previous: U32) -> List<&2,FToken>:
  f_choose(List<&2,FToken>, String.is_empty(s) || f_ascii_char_eq(f_head(s), '\n'),
    u => f_lex_cursor(s, l, c, d, acc, offset, previous),
    u => f_lex_comment(f_tail(s), l, c, d, acc, f_cursor_add(offset, dg_units(f_head(s))), previous))

@unsafe
def f_lex_cursor(+s: String, +l: U32, +c: U32, +d: U32, +acc: List<&2,FToken>, +offset: U32, +previous: U32) -> List<&2,FToken>:
  f_choose(List<&2,FToken>, String.is_empty(s),
    u => List.reverse(&2, FToken, f_choose(List<&2,FToken>, U32.is_eq(offset, 0), u => acc, u => Con{FToken{"<eof>", 0, 0, 0, offset, offset, previous}, acc})),
    u => f_choose(List<&2,FToken>, f_ascii_char_eq(f_head(s), '\n'),
      u => f_lex_cursor(f_tail(s), U32.add(l, 1), 0, d, f_choose(List<&2,FToken>, U32.is_eq(d, 0), u => Con{FToken{"\n", l, c, 0, offset, f_cursor_add(offset, 1), previous}, acc}, u => acc), f_cursor_add(offset, 1), previous),
      u => f_choose(List<&2,FToken>, f_ascii_space(f_head(s)),
        u => f_lex_cursor(f_tail(s), l, U32.add(c, 1), d, acc, f_cursor_add(offset, dg_units(f_head(s))), previous),
        u => f_choose(List<&2,FToken>, f_ascii_char_eq(f_head(s), '#'),
          u => f_lex_comment(s, l, c, d, acc, offset, previous),
          u => f_choose(List<&2,FToken>, f_ascii_char_eq(f_head(s), '"') || f_ascii_char_eq(f_head(s), '\''),
            u => f_lex_scanned(f_scan_quote(f_tail(s), f_head(s), SCon{f_head(s), ""}, 1), l, c, d, 2, acc, offset, previous),
            u => f_choose(List<&2,FToken>, f_ident(f_head(s)) && Bool.not(f_ascii_char_eq(f_head(s), '.')),
              u => f_lex_scanned(f_scan_word(s, "", 0), l, c, d, 1, acc, offset, previous),
              u => f_choose(List<&2,FToken>, f_triple_op(s),
                u => f_lex_cursor(f_tail(f_tail(f_tail(s))), l, U32.add(c, 3), d, Con{FToken{f_three(s), l, c, 0, offset, f_cursor_add(offset, 3), previous}, acc}, f_cursor_add(offset, 3), f_cursor_add(offset, 3)),
                u => f_choose(List<&2,FToken>, f_ident(f_head(s)),
                  u => f_lex_scanned(f_scan_word(s, "", 0), l, c, d, 1, acc, offset, previous),
                  u => f_lex_symbol(s, l, c, d, acc, offset, previous)))))))))

''' + s[b:]
p.write_text(s)
# Mechanical arity changes and exact split-token subranges.
for file in ['front/parser.bend','front/declarations.bend','front/validate.bend']:
 p=P/file;s=p.read_text()
 s=s.replace('FToken{"+", f_line(ts), f_col(ts), 0}', 'FToken{"+", f_line(ts), f_col(ts), 0, f_begin(ts), f_cursor_add(f_begin(ts), 1), f_previous_end(ts)}')
 for symbol in ['+','>','-']:
  s=s.replace('FToken{"'+symbol+'", f_line(ts), U32.add(f_col(ts), 1), 0}', 'FToken{"'+symbol+'", f_line(ts), U32.add(f_col(ts), 1), 0, f_cursor_add(f_begin(ts), 1), f_end(ts), f_cursor_add(f_begin(ts), 1)}')
 s=s.replace('FToken{"", f_line(ts), U32.add(f_col(ts), U32.from_nat(String.length(f_tx(ts)))), 0}', 'FToken{"", f_line(ts), U32.add(f_col(ts), U32.from_nat(String.length(f_tx(ts)))), 0, f_end(ts), f_end(ts), f_end(ts)}')
 p.write_text(s)
change('diagnostic/frontend.bend','FToken{word, line, column, kind}', 'FToken{word, line, column, kind, begin, end, previousEnd}')
p=P/'front/declarations.bend';p.write_text(p.read_text()+'''\n@unsafe\ndef f_parse_indexed(+start: U32, +source: String) -> FResult:\n  fpe_finish(source, f_tops(f_lex_indexed(start, source), Nil{}, Nil{}, False{}))\n''')
# Later source additions are injected before the frozen output writer below.
# RANGE_PATCHES
changes=[]
for p in sorted(P.rglob('*.bend')):
 before=(BASE/'src'/p.relative_to(P)).read_text();after=p.read_text()
 if before!=after:
  rel='src/'+p.relative_to(P).as_posix();changes.append({'file':rel,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'lineDelta':len(after.splitlines())-len(before.splitlines())})
  (OUT/(p.name+'.patch')).write_text(''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='parent/'+rel,tofile='candidate/'+rel)))
config={'project':str(OUT/'project'),'upstream':str(ROOT/'selfhost/.bootstrap/upstream-phase8'),'cpu':'3','jobs':1,'profile':'equality','timeoutMs':30000}
(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n');shutil.copy2(__file__,OUT/Path(__file__).name)
(OUT/'manifest.json').write_text(json.dumps({'complete':True,'parent':str(BASE),'plan':str(ROOT/'experiments/phase16/P16-parser-origins.md'),'changes':changes,'preparerSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()},indent=2)+'\n');print(OUT)
