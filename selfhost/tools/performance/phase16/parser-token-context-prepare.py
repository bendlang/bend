#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,shutil,difflib
ROOT=Path(__file__).resolve().parents[4];BASE=ROOT/'selfhost/build/phase16/parser-semantic-source-05';OUT=ROOT/'selfhost/build/phase16/parser-token-source-01';OUT.mkdir();shutil.copytree(BASE/'project',OUT/'project')
def edit(file,a,b):
 p=OUT/'project/src/front'/file;s=p.read_text();assert s.count(a)==1,(file,a,s.count(a));p.write_text(s.replace(a,b))
f='parser.bend'
edit(f,'u => f_arg_next(f_expr(spaced, 0), end, acc)))','u => f_arg_next(f_choose(FParsed, f_eq(end, ")") && f_eq(f_tx(spaced), "~"), u => f_locate(f_template_expr(f_expr(f_tl(spaced), 0)), f_begin(spaced), False{}, False{}, False{}), u => f_expr(spaced, 0)), end, acc)))')
a='f_choose(FParsed, f_eq(f_tx(ts), "~"), u => f_template_expr(f_expr(f_tl(ts), 0)), u => f_choose(FParsed, f_eq(f_tx(ts), "do"), u => f_do_start(f_tl(ts), f_begin(ts)), u => f_choose(FParsed, f_eq(f_tx(ts), "%"), u => f_rewrite(f_tl(ts)), u => f_atom_base(ts))))'
b='f_choose(FParsed, f_eq(f_tx(ts), "do"), u => f_do_start(f_tl(ts), f_begin(ts)), u => f_choose(FParsed, f_eq(f_tx(ts), "%"), u => f_rewrite(f_tl(ts)), u => f_atom_base(ts)))';edit(f,a,b)
edit(f,'u => f_atom_name(ts),','u => f_choose(FParsed, f_ascii_alpha(f_head(f_tx(ts))) || f_ascii_digit(f_head(f_tx(ts))) || Char.is_eq(f_head(f_tx(ts)), \'_\'), u => f_atom_name(ts), u => fpe_error(ts, "expected term", "a term")),')
edit(f,'u => f_choose(FParsed, f_eq(f_tx(ts), "!"), u => f_bang(n, ts, min),','u => f_choose(FParsed, f_eq(f_tx(ts), "!") && f_eq(f_tx(f_tl(ts)), "(") && U32.is_eq(f_line(ts), f_line(f_tl(ts))) && U32.is_eq(f_col(f_tl(ts)), U32.add(f_col(ts), 1)), u => f_bang(n, ts, min),')
edit(f,'FParsed{kt("Ann", "", 0, 1, [n, ty]), ts}','FParsed{f_choose(KTerm, f_eq(tg(n), "Error"), u => n, u => f_choose(KTerm, f_eq(tg(ty), "Error"), u => ty, u => kt("Ann", "", 0, 1, [n, ty]))), ts}')
f='families.bend';edit(f,'u => kt("Error", "~ arguments require leading template slots on a named template definition", 0, 0, Nil{}))','u => f_templates_error(f_tail_terms(ks(t)), f_choose(U32, f_eq(tg(head), "Ref") && f_eq(tg(kid(t, 0)), "Ref"), u => dx(f_find(nm(head), book)), u => 0), 0, False{}, nm(head)))')
p=OUT/'project/src/front'/f;p.write_text(p.read_text()+'''
# Only failed calls revisit arguments to retain the first bad marker.
@unsafe
def f_templates_error(+args: List<&2,KTerm>, +left: U32, +count: U32, +ordinary: Bool, +name: String) -> KTerm:
  match args:
    case Nil{}: kt("Error", "~ arguments require leading template slots on a named template definition", 0, 0, Nil{})
    case Con{a, rest}:
      f_choose(KTerm, f_eq(tg(a), "TemplateArg"),
        u => f_choose(KTerm, Bool.not(ordinary) && U32.is_gt(left, 0), u => f_templates_error(rest, U32.sub(left, 1), U32.add(count, 1), False{}, name),
          u => fpe_expected_at(k_with_span(a, kb(a), kb(a)), "~ arguments require leading template slots on a named template definition", f_choose(String, Bool.not(ordinary) && U32.is_gt(count, 0), u => "a term (" ++ name ++ " takes " ++ U32.show(count) ++ " ~)", u => "a term"), "'~'")),
        u => f_templates_error(rest, left, count, True{}, name))
''')
config=json.loads((BASE/'workflow.json').read_text());config['project']=str(OUT/'project');(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n');shutil.copy2(__file__,OUT/Path(__file__).name)
changes=[]
for f in ['parser.bend','families.bend']:
 a=BASE/'project/src/front'/f;b=OUT/'project/src/front'/f;x=a.read_text();y=b.read_text();(OUT/(f+'.patch')).write_text(''.join(difflib.unified_diff(x.splitlines(True),y.splitlines(True),fromfile='parent/'+f,tofile='candidate/'+f)));changes.append({'file':'src/front/'+f,'beforeSha256':hashlib.sha256(a.read_bytes()).hexdigest(),'afterSha256':hashlib.sha256(b.read_bytes()).hexdigest()})
ids=['comptime/err_extra.bend','comptime/err_head.bend','comptime/err_later.bend','comptime/err_runtime.bend','flatten/mark_computed_optout.bend','parse/comp_arrow_position.bend','parse/chain_old_spellings_001.bend'];(OUT/'selection.json').write_text(json.dumps({'cases':[{'id':x,'lanes':['parse','check']} for x in ids]},indent=2)+'\n')
(out:=OUT/'manifest.json').write_text(json.dumps({'complete':True,'parent':str(BASE),'plan':'experiments/phase16/P16-parser-token-context.md','changes':changes,'ids':ids},indent=2)+'\n');print(OUT)
