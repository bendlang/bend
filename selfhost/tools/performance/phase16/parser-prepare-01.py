#!/usr/bin/env python3
"""Freeze a source-only parser range candidate before running compiler probes."""
from pathlib import Path
import difflib, hashlib, json, shutil

ROOT = Path(__file__).resolve().parents[4]
OUT = ROOT / 'selfhost/build/phase16/parser-source-01'
BASE = ROOT / 'selfhost/build/phase15/combined-02/snapshot'
OUT.mkdir()
PROJECT = OUT / 'project'
PROJECT.mkdir()
for name in ['src', 'tools', 'tests']:
    shutil.copytree(BASE / name, PROJECT / name)
changes = []

def edit(name, transform):
    p = PROJECT / 'src/front' / name
    before = p.read_text()
    after = transform(before)
    assert after != before, name
    p.write_text(after)
    (OUT / (name + '.patch')).write_text(''.join(difflib.unified_diff(before.splitlines(True), after.splitlines(True), fromfile='a/selfhost/src/front/' + name, tofile='b/selfhost/src/front/' + name)))
    changes.append({'file': str(p.relative_to(ROOT)), 'beforeSha256': hashlib.sha256(before.encode()).hexdigest(), 'afterSha256': hashlib.sha256(after.encode()).hexdigest(), 'physicalLinesDelta': len(after.splitlines()) - len(before.splitlines()), 'bytesDelta': len(after.encode()) - len(before.encode())})

def once(s, old, new):
    assert s.count(old) == 1, (old, s.count(old))
    return s.replace(old, new)

def parser(s):
    s = once(s, 'law fpe_message:\n  for +source: String\n  for +offset: U32', 'law fpe_message:\n  for +source: String\n  for +offset: U32\n  for +end: U32')
    s = s.replace('fpe_message(source, offset, error,', 'fpe_observe(source, rest, offset, error,')
    # The replacement above also reaches the definition; restore its new signature.
    s = once(s, 'def fpe_observe(source, rest, offset, error, observed):', 'def fpe_message(source, offset, end, error, observed):')
    s = once(s, 'dg_snippet(DSpan{source, offset, offset})', 'dg_snippet(DSpan{source, offset, end})')
    begin = s.index('# The pinned parser tests constructor freshness')
    s = s[:begin] + '''# A range is explicit producer data; point diagnostics retain their old path.
@unsafe
def fpe_span(+start: List<&2,FToken>, +end: List<&2,FToken>, +legacy: String, +expected: String, +observed: String) -> FParsed:
  FParsed{kt("Error", nm(f_pn(f_err(start, legacy))), f_line(start), f_col(start), [kt("ParseExpected", expected, 0, 0, Nil{}), kt("ParseToken", f_tx(start), 0, 0, Nil{}), kt("ParseRange", observed, f_line(end), f_col(end), Nil{})]), Nil{}}

@unsafe
def fpe_word(+ts: List<&2,FToken>, +legacy: String, +expected: String) -> FParsed:
  fpe_span(ts, [FToken{"", f_line(ts), U32.add(f_col(ts), U32.from_nat(String.length(f_tx(ts)))), 0}], legacy, expected, "")

@unsafe
def fpe_observe(+source: String, +rest: String, +offset: U32, +error: KTerm, +observed: String) -> String:
  f_choose(String, f_eq(tg(kid(error, 2)), "ParseRange"), u => fpe_range(source, rest, ix(error), qt(error), offset, offset, error, ""), u => fpe_message(source, offset, offset, error, observed))

@unsafe
def fpe_range(+source: String, +rest: String, +line: U32, +column: U32, +offset: U32, +start: U32, +error: KTerm, +acc: String) -> String:
  f_choose(String, U32.is_eq(line, ix(kid(error, 2))) && U32.is_eq(column, qt(kid(error, 2))),
    u => fpe_message(source, start, offset, error, f_choose(String, String.is_empty(nm(kid(error, 2))), u => "'" ++ String.reverse(acc) ++ "'", u => nm(kid(error, 2)))),
    u => f_choose(String, String.is_empty(rest), u => nm(error), u => fpe_range(source, f_tail(rest), f_choose(U32, Char.is_eq(f_head(rest), '\\n'), u => U32.add(line, 1), u => line), f_choose(U32, Char.is_eq(f_head(rest), '\\n'), u => 0, u => U32.add(column, 1)), U32.add(offset, dg_units(f_head(rest))), start, error, SCon{f_head(rest), acc})))
'''
    return s

def declarations(s):
    s = s.replace('fpe_fresh(ts,', 'fpe_word(ts,')
    s = once(s, 'fpe_error(ts, "invalid definition name",', 'fpe_word(ts, "invalid definition name",')
    for name in ['f_case_pats', 'f_case_pat']:
        needle = 'law ' + name + ':'
        a = s.index(needle)
        b = s.index('  FParsed', a)
        s = s[:b] + '  for +start: List<&2,FToken>\n' + s[b:]
    s = once(s, 'f_case_pats(f_tl(ts), indent, heads, rows, Nil{})', 'f_case_pats(f_tl(ts), indent, heads, rows, Nil{}, f_skip(f_tl(ts)))')
    s = once(s, 'def f_case_pats(ts, indent, heads, rows, pats):', 'def f_case_pats(ts, indent, heads, rows, pats, start):')
    s = once(s, 'fpe_error(ts, "one pattern is required per match scrutinee", U32.show(terms_len(heads)) ++ " patterns (one per scrutinee)")', 'fpe_span(start, ts, "one pattern is required per match scrutinee", U32.show(terms_len(heads)) ++ " patterns (one per scrutinee)", "")')
    s = once(s, '0), indent, heads, rows, pats))', '0), indent, heads, rows, pats, start))')
    s = once(s, 'def f_case_pat(p, indent, heads, rows, pats):', 'def f_case_pat(p, indent, heads, rows, pats, start):')
    s = once(s, 'f_case_pats(ts, indent, heads, rows, Con{n, pats})', 'f_case_pats(ts, indent, heads, rows, Con{n, pats}, start)')
    return s

def validate(s):
    return once(s, 'fpe_error(start, "invalid import path", "an import path of plain names (letters, digits, _ and -; the hub\\\'s files import the hub\\\'s)")', 'fpe_span(start, start, "invalid import path", "an import path of plain names (letters, digits, _ and -; the hub\\\'s files import the hub\\\'s)", "\\\'" ++ path ++ "\\\'")')

edit('parser.bend', parser)
edit('declarations.bend', declarations)
edit('validate.bend', validate)
config = {'project': str(PROJECT), 'upstream': str(ROOT / 'selfhost/.bootstrap/upstream-phase8'), 'cpu': '3', 'jobs': 1, 'profile': 'equality', 'timeoutMs': 30000}
(OUT / 'workflow.json').write_text(json.dumps(config, indent=2) + '\n')
identity = lambda p: {'file': str(p), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest(), 'bytes': p.stat().st_size}
shutil.copy2(__file__, OUT / Path(__file__).name)
(OUT / 'manifest.json').write_text(json.dumps({'complete': True, 'scope': 'Existing parser error payload gains optional exact source range and observed override; no successful term/Book/host/runtime ABI changes.', 'inputs': [identity(Path(__file__).resolve()), identity(ROOT / 'experiments/phase16/P16-parser-diagnostics.md'), identity(ROOT / 'design/phase16/parser_diagnostics.md')], 'changes': changes, 'config': identity(OUT / 'workflow.json')}, indent=2) + '\n')
print(OUT)
