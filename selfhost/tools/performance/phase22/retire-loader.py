#!/usr/bin/env python3
"""Loader retirement on an explicit private source snapshot."""
from pathlib import Path
import re
import subprocess
import sys

root = Path(sys.argv[1]).resolve()


def remove_blocks(text, names):
    lines = text.splitlines(keepends=True)
    spans, found = [], set()
    for i, line in enumerate(lines):
        match = re.match(r"(?:def|law|type) ([A-Za-z0-9_]+)\b", line)
        if not match or match[1] not in names:
            continue
        found.add(match[1])
        start = i - 1 if i and lines[i - 1].startswith('@unsafe') else i
        end = i + 1
        while end < len(lines) and (not lines[end].strip() or lines[end][0].isspace()):
            end += 1
        spans.append((start, end))
    assert found == set(names), set(names) - found
    for start, end in reversed(spans):
        del lines[start:end]
    return ''.join(lines)


p = root / 'src/load/modules.bend'
s = p.read_text()
assert 'FParsedSource' in s
s = remove_blocks(s, {
    'FLoaded', 'f_qual_result', 'f_qual_terms', 'f_qual_def', 'f_loaded_result',
    'f_load_module', 'f_load_source', 'f_load_parsed', 'f_load_imports',
    'f_load_import_next', 'f_parse_at', 'f_qual_optional', 'f_qual_term',
    'f_qual_defs', 'f_resolve_name', 'f_load', 'f_parse_source', 'f_parse_source_located',
})
s = s.replace('FParsedSource', 'FCompletedSource').replace('f_source_parsed', 'f_source_completed')
s = s.replace('def compiler_load_abi() -> U32:\n  1', 'def compiler_load_abi() -> U32:\n  2')
s = s.replace('FParseScope{prior, index_build(List.reverse(&2,KDef,prior)), ns, aliases, True{}}',
              'FParseScope{prior, index_build(List.reverse(&2,KDef,prior)), ns, aliases}')
s = s.replace("# Invocation-local parse handoff. The driver supplies the unqualified result of\n# this compiler's parser; graph elaboration and validation still run normally.",
              "# Invocation-local completion handoff. Only the exact result produced by this\n# compiler's contextual completion is accepted; raw parsed trees are not.")
s = s.replace('# Location ownership is separate from raw/parsed source delivery.',
              '# Location ownership is separate from text/completed source delivery.')
p.write_text(s)

p = root / 'src/load/graph.bend'
s = remove_blocks(p.read_text(), {
    'f_alias_terms', 'f_alias_term', 'f_alias_deferred', 'f_alias_defs',
    'f_module_defs', 'f_module_def', 'f_main_names', 'f_main_result_names', 'f_main_order',
})
s = s.replace('f_alias_terms(ks(t), imports, scope)', 'ks(t)')
s = s.replace('f_alias_defs(book, imports, prior)', 'f_graph_fill_defs(book, imports, prior)')
s = s.replace('f_module_defs(book, book, f_family_book(prior), ns, imports)', 'f_context_modules(book, ns)')
s = s.replace('f_context_unwrap(dv(d))', 'dv(d)')
old = 'f_choose(KTerm, f_eq(tg(dv(d)), "Body"), u => kt("Body", "", fc_start(ks(dt(d)), dt(old), kid(dv(d), 1), True{}), 0, ks(dv(d))), u => dv(d))'
assert s.count(old) == 1
s = s.replace(old, 'dv(d)')
s = s.replace('# An import alias is an alternative until the lexical scope has its say.\n', '')
start = s.index('# Reporting uses the main module')
end = s.index('# Request-local trace', start)
s = s[:start] + s[end:]
s = s.replace('# Imported fills retain their raw telescope until dependencies have loaded.\n# The temporary kind protects the already-canonical law type and name from\n# module qualification; f_module_def eliminates it before checker entry.',
              '# Imported fills retain telescope metadata until dependencies have loaded.\n# The temporary kind protects the canonical law type/name from qualification;\n# contextual module completion eliminates it before checker entry.')
pos = s.index('@unsafe\ndef f_graph_fill_alias')
s = s[:pos] + '''@unsafe
def f_graph_fill_defs(+defs: List<&2,KDef>, +imports: List<&2,KTerm>, +scope: List<&2,KDef>) -> List<&2,KDef>:
  match defs:
    case Nil{}: Nil{}
    case Con{d, rest}:
      Con{f_graph_fill_alias(KDef{dn(d), dk(d), da(d), dx(d), dt(d), dv(d), f_graph_fill_defs(dc(d), imports, scope), db(d), du(d)}, imports, scope), f_graph_fill_defs(rest, imports, scope)}

''' + s[pos:]
p.write_text(s)

p = root / 'src/diagnostic/frontend.bend'
s = p.read_text()
assert s.count('FParsedSource') == 2
p.write_text(s.replace('FParsedSource', 'FCompletedSource'))

patch = root.parents[1] / 'loader-host-source-01/host.patch'
subprocess.run(['patch', '-p1', '-i', str(patch)], cwd=root, check=True)
p = root / 'tools/typed-driver.mjs'
s = p.read_text()
assert s.count("'f_main_names',") == 1
p.write_text(s.replace("'f_main_names',", ''))
