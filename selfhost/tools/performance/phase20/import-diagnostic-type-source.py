"""Replace the datatype constructor checkpoint in a fresh isolated source02."""
from pathlib import Path
import json,hashlib,shutil,difflib,re
R=Path(__file__).resolve().parents[4];P=R/'selfhost/build/phase20';BASE=P/'import-diagnostic-source-01/project';O=P/'import-diagnostic-source-02'
baseline=json.loads((P/'import-diagnostic-type-baseline-02/report.json').read_text());assert baseline['complete']and baseline['pass']and baseline['count']==50
O.mkdir();C=O/'project';shutil.copytree(BASE,C);p=C/'src/front/declarations.bend';old=p.read_text()
start=old.index('@unsafe\ndef f_type_ctors(');end=old.index('@unsafe\ndef f_type_ctor(',start)
newpart='''@unsafe
def f_type_ctors(name, pars, ty, ts, book, imports, ctors, scope):
  f_choose(FRawResult, (f_ascii_alpha(f_head(f_tx(ts))) || Char.is_eq(f_head(f_tx(ts)), '_')) && Bool.not(f_eq(f_tx(ts), "def") || f_eq(f_tx(ts), "type") || f_eq(f_tx(ts), "law")),
    u => f_type_ctor_header(name, pars, ty, ts, book, imports, ctors, scope),
    u => f_tops(ts, Con{KDef{name, "ADT", terms_len(pars), 0, f_tbind(pars, ty), atom("Absent"), List.reverse(&2, KDef, ctors), False{}, False{}}, book}, imports, False{}, scope))

@unsafe
def f_type_ctor_header(
  +name: String, +pars: List<&2,KTerm>, +ty: KTerm, +ts: List<&2,FToken>,
  +book: List<&2,KDef>, +imports: List<&2,KTerm>, +ctors: List<&2,KDef>, +scope: FParseScope,
) -> FRawResult:
  f_choose(FRawResult, Bool.not(f_valid_name(f_tx(ts))),
    u => f_result(book, f_pn(fpe_name_error(ts)), imports),
    u => f_choose(FRawResult, Bool.not(f_eq(f_alias(f_tx(ts), imports), f_tx(ts))),
      u => f_result(book, f_pn(fpe_word(ts, "an import alias cannot name a constructor", "a fresh constructor name (" ++ f_import_alias_head(f_tx(ts)) ++ " is an import's alias)")), imports),
    u => f_choose(FRawResult, Bool.not(f_eq(dk(f_find(f_tx(ts), ctors)), "Missing")) || f_decl_ctor_taken(f_tx(ts), book, scope),
      u => f_result(book, f_pn(fpe_word(ts, "expected a fresh constructor name (duplicate declaration: " ++ f_tx(ts) ++ ")", "a fresh constructor name (duplicate declaration: " ++ f_tx(ts) ++ ")")), imports),
    u => f_choose(FRawResult, f_eq(f_tx(f_skip(f_tl(ts))), "{"),
      u => f_type_ctor(name, pars, ty, f_tx(ts), f_tele(f_tl(f_skip(f_tl(ts))), "}", Nil{}), book, imports, ctors, scope),
      u => f_result(book, f_pn(fpe_error(f_skip(f_tl(ts)), "expected {", "'{'")), imports)))))

'''
new=old[:start]+newpart+old[end:];p.write_text(new)
(O/'declarations-parent01.patch').write_text(''.join(difflib.unified_diff(old.splitlines(True),new.splitlines(True),fromfile='source01/src/front/declarations.bend',tofile='source02/src/front/declarations.bend')))
installed=(R/'selfhost/build/phase19/instance-source-04/project/src/front/declarations.bend').read_text()
(O/'declarations-phase19.patch').write_text(''.join(difflib.unified_diff(installed.splitlines(True),new.splitlines(True),fromfile='phase19/src/front/declarations.bend',tofile='phase20/src/front/declarations.bend')))
config=json.loads((BASE.parent/'workflow.json').read_text());config['project']=str(C);(O/'workflow.json').write_text(json.dumps(config,indent=2)+'\n')
identity=lambda p:{'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
delta=lambda old,new:{'physicalLines':len(new.splitlines())-len(old.splitlines()),'bytes':len(new.encode())-len(old.encode()),**{k:len(re.findall(r'^'+word+' ',new,re.M))-len(re.findall(r'^'+word+' ',old,re.M))for k,word in [('definitions','def'),('laws','law'),('types','type')]}}
inputs=[Path(__file__),R/'design/phase20/import-diagnostic-type-correction.md',P/'import-diagnostic-type-controls-01/plan.json',P/'import-diagnostic-type-baseline-02/report.json',BASE.parent/'manifest.json']
(O/'manifest.json').write_text(json.dumps({'kind':'phase20-type-constructor-checkpoint','complete':True,'frozen':True,'parent':str(BASE),'project':str(C),'changedFiles':['src/front/declarations.bend'],'deltaParent01':delta(old,new),'deltaPhase19':delta(installed,new),'hostChanges':False,'inputs':[identity(p)for p in inputs],'members':{str(f.relative_to(C)):{'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'bytes':f.stat().st_size,'mode':f.stat().st_mode&0o777}for f in sorted(C.rglob('*'))if f.is_file()},'installed':False},indent=2)+'\n');print(O)
