from pathlib import Path
import difflib, hashlib, json, shutil

root=Path(__file__).resolve().parents[4];phase=root/'selfhost/build/phase16'
base=phase/'module-names-source-02/project'
wave4=phase/'wave4-source-02/project'
decl=phase/'parser-declaration-source-01/project'
imp=phase/'spans-import-source-04/project'
out=phase/'wave6-source-01';out.mkdir();shutil.copytree(base,out/'project')
def ident(p):return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
def replace(s,a,b):
    assert s.count(a)==1,(a,s.count(a))
    return s.replace(a,b)
inputs=[]
for folder,expected in [('parser-declaration-source-01-handoff',{'src/front/declarations.bend','src/front/validate.bend'}),('spans-import-source-04-handoff',{'src/front/declarations.bend','src/front/validate.bend','src/front/parser.bend','src/load/imports.bend','src/load/graph.bend'})]:
    file=phase/folder/'manifest.json';inputs.append(ident(file))
    # Compare complete owner sources rather than trusting selected patch hunks.
    source=decl if folder.startswith('parser-') else imp
    actual={str(p.relative_to(wave4)) for p in (wave4/'src').rglob('*') if p.is_file() and p.read_bytes()!=(source/p.relative_to(wave4)).read_bytes()}
    assert actual==expected,(folder,actual,expected)
    for f in sorted(actual):inputs.extend([ident(wave4/f),ident(source/f)])
for f in ['src/front/declarations.bend','src/front/validate.bend']:
    assert (base/f).read_bytes()==(wave4/f).read_bytes()
    shutil.copy2(decl/f,out/'project'/f)
for f in ['src/front/parser.bend','src/load/imports.bend']:
    assert (base/f).read_bytes()==(wave4/f).read_bytes()
    shutil.copy2(imp/f,out/'project'/f)
f='src/front/declarations.bend';p=out/'project'/f;s=p.read_text()
s=replace(s,'  f_import_path(ts, ts, "", book, imports)','  f_import_path(f_tl(ts), f_tl(ts), "", book, imports, ts)')
s=replace(s,'u => f_import(f_tl(ts), book, imports)','u => f_import(ts, book, imports)')
def function(s,name):
    start=s.index('def '+name+'(');end=s.index('\n\n',start)
    return s[start:end]
s=replace(s,function(s,'f_named_top'),function((imp/f).read_text(),'f_named_top'));p.write_text(s)
f='src/front/validate.bend';p=out/'project'/f;s=p.read_text()
s=replace(s,function(s,'f_import_alias'),function((imp/f).read_text(),'f_import_alias'))
s=replace(s,'f_err(f_pr(p), "an import alias can only name a law fill without a return annotation")','fpe_word(nameTokens, "an import alias can only name a law fill without a return annotation", "a fresh name (" ++ f_import_alias_head(name) ++ " is an import\'s alias)")')
p.write_text(s)
f='src/load/graph.bend';p=out/'project'/f;s=p.read_text();s=replace(s,function(s,'f_alias_named'),function((imp/f).read_text(),'f_alias_named'));p.write_text(s)
changes=[];patches=[]
for p in sorted((out/'project/src').rglob('*')):
    if not p.is_file():continue
    f=str(p.relative_to(out/'project'));old=base/f
    if old.read_bytes()!=p.read_bytes():
        changes.append({'path':f,'before':ident(old),'after':ident(p)})
        patches.extend(difflib.unified_diff(old.read_text().splitlines(True),p.read_text().splitlines(True),fromfile=f,tofile=f))
patch=out/'combined.patch';patch.write_text(''.join(patches))
(out/'manifest.json').write_text(json.dumps({'parent':str(base),'plan':ident(root/'design/phase16/wave6-integration.md'),'tool':ident(Path(__file__)),'inputs':inputs,'changes':changes,'patch':ident(patch)},indent=2)+'\n')
(out/'workflow.json').write_text(json.dumps({'project':str(out/'project'),'upstream':str(root/'selfhost/.bootstrap/upstream-phase8'),'profile':'equality','cpu':'0','jobs':1},indent=2)+'\n')
shutil.copy2(__file__,out/'consumed-tool.py');print(out)
