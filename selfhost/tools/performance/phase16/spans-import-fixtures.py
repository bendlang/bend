from pathlib import Path
import json,hashlib,shutil
R=Path(__file__).resolve().parents[4];out=R/'selfhost/build/phase16/spans-import-fixtures-01';out.mkdir();cases=[{'id':n+'.bend','lanes':['parse','check']} for n in ['import/alias_decl','import/alias_shadow','import/alias_twice','import/c_suffix_module','import/parent_segments','import/suffix_refused','reg/import_head']]
(out/'lib.bend').write_text('import Base\nlaw seed:\n  Nat\ndef value() -> Nat:\n  1n\n')
examples={
 'header-spaces':('  import   Wat   # retained comment\ndef main() -> Type: Type\n',False),
 'header-tabs-crlf':('\timport\tWat\t# retained\r\ndef main() -> Type: Type\r\n',False),
 'header-eof':('import Wat',False),
 'header-extra':('import ./lib.bend as M extra\n',False),
 'header-bad-alias':('import ./lib.bend as M.foo\n',False),
 'header-path-space':('import ./lib .bend as M\n',False),
 'suffix-before-path':('import ./bad+path.txt as M\n',False),
 'duplicate-comment':('import ./lib.bend as M\n  import  ./lib.bend  as M # same alias\n',False),
 'duplicate-before-bad-path':('import ./lib.bend as M\nimport ./bad+path.bend as M\n',False),
 'extension-before-duplicate':('import ./lib.bend as M\nimport ./bad.txt as M\n',False),
 'ordinary-fill':('import Base\nimport ./lib.bend as M\ndef M.seed():\n  0n\n',True),
 'annotated-fill':('import Base\nimport ./lib.bend as M\ndef M.seed() -> Nat:\n  0n\n',False),
 'alias-name':('import Base\nimport ./lib.bend as M\ndef M.new() -> Nat:\n  0n\n',False),
 'alias-type':('import ./lib.bend as M\ntype M.New is Data:\n  Mk{}\n',False),
 'alias-law':('import Base\nimport ./lib.bend as M\nlaw M.new:\n  Nat\n',False),
}
for name,(text,accept) in examples.items():
 p=out/(name+'.bend');p.write_text(text);case={'id':'p16-import/'+name,'file':str(p),'lanes':['parse','check'],'accept':accept};
 if not accept:case['rejectPhase']='parse'
 cases.append(case)
(out/'selection.json').write_text(json.dumps({'cases':cases,'scope':'All14 original import observations plus30 independent header/ordering/imported-law/alias declaration boundaries; strict failures retained.'},indent=2)+'\n');shutil.copy2(__file__,out/Path(__file__).name)
(out/'manifest.json').write_text(json.dumps({'files':[{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in sorted(out.glob('*.bend'))]},indent=2)+'\n')
print(out)
