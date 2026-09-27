"""Count this prototype and its existing Bend helper dependency blocks."""
import json
from pathlib import Path
import re
import sys

own = Path(__file__).resolve().parent
repo = own.parents[3]
snapshot = Path(sys.argv[1]).resolve() / 'sources'
blocks, laws, types = {}, {}, {}
for source in snapshot.glob('*.bend'):
    lines = source.read_text().splitlines(keepends=True)
    starts = []
    for index, line in enumerate(lines):
        match = re.match(r'^(type|law|def)\s+([^\s(<:]+)', line)
        if match:
            start = index - 1 if index and lines[index - 1].strip() == '@unsafe' else index
            starts.append((start, index, match[1], match[2]))
    for position, (start, declaration, kind, name) in enumerate(starts):
        end = starts[position + 1][0] if position + 1 < len(starts) else len(lines)
        text = ''.join(lines[start:end]).rstrip() + '\n'
        item = {'name': name, 'file': source.name, 'line': declaration + 1,
                'physical': len(text.splitlines()), 'nonblank': sum(bool(line.strip()) for line in text.splitlines()),
                'bytes': len(text.encode()), 'text': text}
        {'def': blocks, 'law': laws, 'type': types}[kind][name] = item
roots = ['sv_supported', 'sv_observe', 'sv_observe_head', 'sv_equal']
seen, pending = set(), roots[:]
while pending:
    name = pending.pop()
    if name in seen:
        continue
    seen.add(name)
    masked = re.sub(r'"(?:\\.|[^"\\])*"|#[^\n]*', ' ', blocks[name]['text'])
    pending += [word for word in re.findall(r'\b[A-Za-z_][A-Za-z_0-9]*\b', masked) if word in blocks and word not in seen]
shared_defs = [blocks[name] for name in sorted(seen) if not name.startswith('sv_')]
shared_laws = [laws[name] for name in sorted(seen) if name in laws and not name.startswith('sv_')]
used = '\n'.join(blocks[name]['text'] for name in seen)
shared_types = [item for name, item in types.items() if not name.startswith('SV') and re.search(r'\b' + name + r'\b', used)]
clean = lambda items: [{key: value for key, value in item.items() if key != 'text'} for item in items]
def count(source):
    data = source.read_bytes()
    lines = data.decode().splitlines()
    return {'file': str(source.relative_to(repo)), 'physical': len(lines),
            'nonblank': sum(bool(line.strip()) for line in lines), 'bytes': len(data)}
report = {
    'method': 'Conservative lexical dependency closure with strings/comments masked. Block counts exclude trailing blank separators; whole-module counts include them. Shared Base primitives remain runtime/library dependencies.',
    'prototype': count(own / 'semantic-values.bend'),
    'definitions': sum(item['file'] == 'semantic-values.bend' for item in blocks.values()),
    'forwardLaws': sum(item['file'] == 'semantic-values.bend' for item in laws.values()),
    'types': sum(item['file'] == 'semantic-values.bend' for item in types.values()),
    'sharedDefinitions': clean(shared_defs), 'sharedLaws': clean(shared_laws), 'sharedTypes': clean(shared_types),
    'prototypeFunctionsUnreachableFromPublicRoots': [name for name in blocks if name.startswith('sv_') and name not in seen],
    'reusedBlockTotals': {key: sum(item[key] for item in shared_defs + shared_laws + shared_types) for key in ['physical', 'nonblank', 'bytes']},
    'auxiliary': [count(source) for source in sorted(own.iterdir()) if source.suffix in ['.mjs', '.py']],
    'productionLinesDeleted': 0, 'productionLinesAdded': 0,
    'oldWholePool': {'normalize': len((snapshot / 'normalize.bend').read_text().splitlines()),
                    'graph': len((snapshot / 'graph.bend').read_text().splitlines()),
                    'warning': '985 minus prototype is not a net saving. Old modules implement excluded semantics and explicit work stacks, and the prototype retains the listed helpers.'},
}
(own / 'counts.json').write_text(json.dumps(report, indent=2) + '\n')
print(json.dumps({key: report[key] for key in ['prototype', 'definitions', 'forwardLaws', 'types', 'reusedBlockTotals']}))
