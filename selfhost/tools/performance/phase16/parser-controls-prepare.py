#!/usr/bin/env python3
from pathlib import Path
import json, hashlib, shutil
ROOT=Path(__file__).resolve().parents[4]
OUT=ROOT/'selfhost/build/phase16/parser-controls-input-01'
OUT.mkdir()
inherited=ROOT/'selfhost/build/phase15/carets-prepare-01/parser-controls.json'
cases=json.loads(inherited.read_text())['cases']
cases += [{'label':label,'source':source,'requireExact':True} for label,source in [
 ('constructor-name','type A is Data:\n  Long{}\ntype B is Data:\n  Long{}\n'),
 ('constructor-spaced','type A is Data:\n  Long{}\ntype B is Data:\n  Long {}\n'),
 ('constructor-tab','type A is Data:\n  Long{}\ntype B is Data:\n\tLong{}\n'),
 ('declaration-word','def Vec.2d() -> U32:\n  0\n'),
 ('arity-two','def f(x: U32) -> U32:\n  match x:\n    case a, b:\n      0\n'),
 ('arity-one','def f(x: U32, y: U32) -> U32:\n  match x, y:\n    case a:\n      0\n'),
 ('arity-spaces','def f(x: U32) -> U32:\n  match x:\n    case a ,   b   :\n      0\n'),
 ('arity-unicode-before','# 😀\ndef f(x: U32) -> U32:\n  match x:\n    case a, b:\n      0\n'),
 ('arity-tab','def f(x: U32) -> U32:\n  match x:\n    case a,\tb:\n      0\n'),
 ('earlier-duplicate','type A is Data:\n  Long{}\n  Long{}\ndef bad( -> U32:\n  !\n'),
 ('earlier-body','def main() -> U32:\n  !\ntype A is Data:\n  Long{}\n  Long{}\n'),
 ('range-positive','type A is Data:\n  Long{}\ndef f(x: A) -> U32:\n  match x:\n    case Long{}:\n      0\n')]]
(OUT/'controls.json').write_text(json.dumps({'cases':cases},indent=2)+'\n')
census=json.loads((ROOT/'selfhost/build/phase16/parser-census-01/report.json').read_text())
family=[r for r in census['rows'] if r['group']=='same-expectation-other-observation-or-detail']
assert len(family)==24
(OUT/'range-selection.json').write_text(json.dumps({'cases':[{'id':r['id'],'lanes':['parse','check']} for r in family]},indent=2)+'\n')
shutil.copy2(__file__,OUT/Path(__file__).name)
(OUT/'manifest.json').write_text(json.dumps({'inputs':[{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in [Path(__file__),inherited,ROOT/'selfhost/build/phase16/parser-census-01/report.json']],'cases':len(cases),'rangeFamilyFixtures':len(family)},indent=2)+'\n')
print(OUT)
