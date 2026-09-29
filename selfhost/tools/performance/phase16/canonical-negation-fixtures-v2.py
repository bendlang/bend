from pathlib import Path
import hashlib, json, shutil

root=Path(__file__).resolve().parents[4]
out=root/'selfhost/build/phase16/canonical-fixtures-02'
out.mkdir()
sources={
 'root-alias.bend': '''type Unit is Type:
  Unit{}
def Empty() -> Type: Unit
law probe: {Unit{} != Unit{} : Unit}
def probe(): e => Unit{}
def main() -> Unit: Unit{}
''',
 'module-capture.bend': '''import ./bad.bend as M
def main() -> M.Thing: M.Thing{}
''',
 'bad.bend': '''type Thing is Type:
  Thing{}
def Empty() -> Type: Thing
law probe: {Thing{} != Thing{} : Thing}
def probe(): e => Thing{}
''',
 'explicit-module.bend': '''import ./good.bend as M
def main() -> M.Thing: M.Thing{}
''',
 'good.bend': '''type Thing is Type:
  Thing{}
def Empty() -> Type: Thing
law probe: {Thing{} == Thing{} : Thing} -> Empty
def probe(): e => Thing{}
''',
 'missing-global.bend': '''type Thing is Type:
  Thing{}
law probe: {Thing{} != Thing{} : Thing}
def probe(): e => Thing{}
def main() -> Thing: Thing{}
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
