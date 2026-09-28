"""Build an isolated one-file feasibility helper; never edit maintained files."""
import hashlib
import json
from pathlib import Path
import sys

root = Path(__file__).resolve().parents[4]
out = Path(sys.argv[1]).resolve()
out.mkdir()
old_path = root / 'selfhost/build/phase12/integrated-03/snapshot/tools/development/equality.mjs'
tools = root / 'selfhost/tools/performance/phase13'
inputs = [Path(__file__), old_path, tools / 'rewriter-structure.mjs',
          tools / 'rewriter-v5.mjs', tools / 'rewriter-selector-const.mjs',
          root / 'design/phase13/integration.md']

def identity(file):
    raw = file.read_bytes()
    return {'file': str(file), 'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()}

report = {'kind': 'phase13-self-contained-maintained-helper-preparation', 'complete': False,
          'inputs': [identity(p) for p in inputs],
          'scope': 'One-file feasibility, original provenance/contracts plus shared structure and profile6; no checked build, integration or speed result.'}
consumed = out / 'consumed'
consumed.mkdir()
for file in inputs:
    (consumed / file.name).write_bytes(file.read_bytes())

def once(text, before, after):
    assert text.count(before) == 1, before
    return text.replace(before, after)

try:
    old = old_path.read_text()
    header = old[:old.index('// The pinned emitter produces')]
    header = once(header, "const runtimeHash='9e9845", "const legacyRuntimeHash='9e9845")
    header = once(header, '{version:1,pin,runtimeHash,bodyHashes', '{version:1,pin,runtimeHash:legacyRuntimeHash,bodyHashes')
    header = once(header, 'const profiles=Object.freeze([legacyProfile,currentTailProfile,',
                  'const currentSelectorProfile=Object.freeze({...currentTailProfile,version:6});\n'
                  'const profiles=Object.freeze([legacyProfile,currentSelectorProfile,currentTailProfile,')
    header += 'const runtimeHash = currentProfile.runtimeHash;\nconst marker = prefixEnd;\n\n'

    structure = (tools / 'rewriter-structure.mjs').read_text()
    structure = structure[structure.index('export function tokens'):].replace('export function ', 'function ')
    structure = once(structure, 'function moduleView(source) {',
                     'function moduleView(source, profileRuntimeHash = currentProfile.runtimeHash) {')
    structure = once(structure, 'sha(source.slice(0, start)), runtimeHash,', 'sha(source.slice(0, start)), profileRuntimeHash,')
    structure = once(structure, "    assert.match(name, /^\\$[\\w$]+\\$$/);\n    assert.ok(!functions.has(name), 'Duplicate generated binding');",
                     "    requireThat(/^\\$[\\w$]+\\$$/.test(name ?? '') && !functions.has(name), 'Unsupported or duplicate top-level function: ' + name);")
    structure = once(structure, 'source: source.slice(ts[first].start, ts[last].end)});',
                     'sourceStart: ts[first].start, sourceEnd: ts[last].end,\n      source: source.slice(ts[first].start, ts[last].end)});')
    structure = once(structure, "  assert.equal(ts[end]?.text, 'export');\n  assert.equal(ts[end + 1]?.text, 'default');\n  assert.equal(ts[end + 2]?.text, '{');\n  assert.equal(ts[end + 2].close, ts.length - 2);\n  assert.equal(ts.at(-1).text, ';');",
                     "  requireThat(ts[end]?.text === 'export' && ts[end + 1]?.text === 'default' && ts[end + 2]?.text === '{', 'Unsupported module exports');\n"
                     "  requireThat(ts[end + 2].close === ts.length - 2 && ts.at(-1)?.text === ';', 'Unexpected top-level code');")

    existing_passes = (tools / 'rewriter-v5.mjs').read_text()
    existing_passes = existing_passes[existing_passes.index('function choiceBody'):existing_passes.index('export function transform(')].replace('export function ', 'function ')
    selectors = (tools / 'rewriter-selector-const.mjs').read_text()
    selectors = selectors[selectors.index('export function lowerSelectors'):selectors.index('export function transform(')].replace('export function ', 'function ')

    scalar = old[old.index('export function transformEquality'):old.index('function verifyBootstrap')]
    a, b = scalar.index('  const ts=tokens(source,start)'), scalar.index('  const exports=[];')
    scalar = scalar[:a] + '  const view=moduleView(source,profile.runtimeHash),{ts,functions}=view;\n  const i=view.end,exportsEnd=ts[i+2].close;\n' + scalar[b:]
    scalar = once(scalar, 'functions.get(ts[j].text)?.start===ts[j-1].start', 'functions.get(ts[j].text)?.sourceStart===ts[j-1].start')
    scalar = once(scalar, 'source.slice(0,target.start)+replacement+source.slice(target.end)',
                  'source.slice(0,target.sourceStart)+replacement+source.slice(target.sourceEnd)')
    scalar = scalar.replace('transformChoices(equalitySource,profile.version>=5)', 'lowerChoices(equalitySource,profile.version>=5)')
    scalar = once(scalar, 'if(profile.version===5){', 'if(profile.version>=5){')
    scalar = once(scalar, 'const tail=transformTailChoices(choice.source);', 'const tail=lowerLeaves(choice.source);')
    scalar = once(scalar, '      return {source:tail.source,stats:{...stats,choices:choice.report,tailChoices:tail.report}};',
                  "      const loweredStats={...stats,choices:choice.report,tailChoices:tail.report};\n"
                  "      if(profile.version===5)return {source:tail.source,stats:loweredStats};\n"
                  "      const selected=lowerSelectors(tail.source,{families:['$norm_eval_node$','$check_node$','$norm_match$','$norm_args$','$ffw_walk$','$infer_node$']});\n"
                  "      return {source:selected.source,stats:{...loweredStats,selectors:selected.report}};")
    result = header + structure + '\n' + existing_passes + '\n' + selectors + '\n' + scalar + old[old.index('function verifyBootstrap'):]
    assert not any('from ' in line and not "from 'node:" in line for line in result.splitlines() if line.startswith('import '))
    target = out / 'project/tools/development/equality.mjs'
    target.parent.mkdir(parents=True)
    target.write_text(result)
    report['helper'] = identity(target)
    report['complexity'] = {'physical': len(result.splitlines()), 'nonblank': sum(bool(line.strip()) for line in result.splitlines()),
                            'bytes': len(result.encode()), 'allHistoricalProfilesIncluded': True, 'externalImports': 'Node builtins only'}
    assert report['inputs'] == [identity(p) for p in inputs]
    report['inputsVerified'] = True
    report['complete'] = True
except BaseException as error:
    report['error'] = repr(error)
    raise
finally:
    (out / 'preparation.json').write_text(json.dumps(report, indent=2) + '\n')
    print(json.dumps({'complete': report['complete'], 'helper': report.get('helper'), 'complexity': report.get('complexity')}))
