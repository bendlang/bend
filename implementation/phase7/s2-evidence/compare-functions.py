#!/usr/bin/env python3
"""Conservative generated-JS dependency comparison; false dependencies are safe.

Identifiers in strings/comments also count. The generated format has top-level
named function declarations followed by an export object. No JS is rewritten.
This establishes unchanged reachable function text, not semantic equivalence of
changed roots. Those require independent behavioral controls.
"""
import hashlib, json, pathlib, re, sys

def read(file):
    p = pathlib.Path(file).resolve()
    s = p.read_text()
    end = s.index('export default {')
    starts = list(re.finditer(r'^function ([A-Za-z_$][\w$]*)\(', s[:end], re.M))
    funcs = {}
    for i, match in enumerate(starts):
        name = match[1]
        assert name not in funcs
        stop = starts[i+1].start() if i+1 < len(starts) else end
        funcs[name] = s[match.start():stop]
    roots = dict(re.findall(r'"([^"\n]+)": run_lib\(([^,]+), \d+\)', s[end:]))
    return {'file':str(p), 'sha256':hashlib.sha256(s.encode()).hexdigest(),
            'bytes':len(s.encode()), 'prefix':s[:starts[0].start()],
            'exports':s[end:], 'roots':roots, 'functions':funcs}

def closure(root, funcs):
    done, todo = set(), [root]
    while todo:
        name = todo.pop()
        if name in done: continue
        done.add(name)
        refs = set(re.findall(r'[A-Za-z_$][\w$]*', funcs[name])) & funcs.keys()
        todo.extend(refs - done)
    return done

before, after = map(read, sys.argv[1:3])
assert before['roots'] == after['roots']
assert before['prefix'] == after['prefix']
assert before['exports'] == after['exports']
a, b = before['functions'], after['functions']
changed = sorted(n for n in a.keys() & b.keys() if a[n] != b[n])
rows = []
for export, symbol in before['roots'].items():
    old, new = closure(symbol, a), closure(symbol, b)
    different = sorted(n for n in old|new if a.get(n) != b.get(n))
    rows.append({'export':export, 'beforeFunctions':len(old),
                 'afterFunctions':len(new), 'unchanged':not different,
                 'differentFunctions':different})
report = {'scope':'Generated function text and conservative identifier closure; changed roots need behavioral tests.',
          'inputs':[{k:v for k,v in x.items() if k in ['file','sha256','bytes']} for x in [before,after]],
          'sameExports':True, 'samePrefix':True, 'sameExportWrappers':True,
          'changed':changed, 'removed':sorted(a.keys()-b.keys()),
          'added':sorted(b.keys()-a.keys()), 'roots':rows}
pathlib.Path(sys.argv[3]).write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps({'changed':changed, 'removed':report['removed'],
                  'unchangedRoots':sum(r['unchanged'] for r in rows), 'roots':len(rows)}))
