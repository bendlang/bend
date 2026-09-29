from pathlib import Path
import hashlib, json, shutil

root=Path(__file__).resolve().parents[4]
out=root/'selfhost/build/phase16/canonical-fixtures-01'
out.mkdir()
sources={
 'root-alias.bend': '''type Unit is Type:
  Unit{}
def Empty() -> Type: Unit
law probe: {Unit{} != Unit{} : Unit}
def probe(): e => Unit{}
def main() -> U32: 0
''',
 'module-capture.bend': '''import Base
import ./bad.bend as M
def main() -> U32: 0
''',
 'bad.bend': '''def Empty() -> Type: Unit
law probe: {0n != 0n : Nat}
def probe(): e => Unit{}
''',
 'explicit-module.bend': '''import Base
import ./good.bend as M
def main() -> U32: 0
''',
 'good.bend': '''def Empty() -> Type: Unit
law probe: {0n == 0n : Nat} -> Empty
def probe(): e => Unit{}
''',
 'missing-global.bend': '''law probe: {0 != 0 : U32}
def probe(): e => 0
def main() -> U32: 0
''',
}
identities=[]
for name,source in sources.items():
 p=out/name;p.write_text(source);identities.append({'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
selection=[{'id':'check/neq_qualified_capture.bend','lanes':['check']},{'id':'check/neq_reflexivity.bend','lanes':['check']}]
for name,accept in [('root-alias',True),('module-capture',False),('explicit-module',True),('missing-global',False)]:
 row={'id':'canonical/'+name,'file':str(out/(name+'.bend')),'lanes':['check'],'accept':accept}
 if not accept:row['rejectPhase']='check'
 selection.append(row)
(out/'selection.json').write_text(json.dumps(selection,indent=2)+'\n')
(out/'manifest.json').write_text(json.dumps({'kind':'phase16-canonical-reference-fixtures','inputs':identities,'toolSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()},indent=2)+'\n')
shutil.copy2(__file__,out/'consumed-tool.py')
print(out)
