#!/usr/bin/env python3
import pathlib,shutil,json,hashlib,difflib
r=pathlib.Path(__file__).resolve().parents[4];base=r/'selfhost/build/phase16/spans-lambda-source-02';parent=base/'project';out=r/'selfhost/build/phase16/spans-lambda-source-03';assert not out.exists();p=out/'project';shutil.copytree(parent,p)
f=p/'src/core/term.bend';s=f.read_text();s+='''
# Scope flattening rebuilds a binder via a temporary pattern variable. Restore
# only its optional quantity syntax after that existing semantic operation.
@unsafe
def k_lambda_presence(+t: KTerm, +present: Bool) -> KTerm:
  match t:
    case KTerm{tag, name, id, quant, kids, removed, begin, end}:
      kc(KTerm, String.eq(tag, "Lam"), u => KLambda{name, id, quant, kids, removed, begin, end, present}, u => t)
    case KLambda{name, id, quant, kids, removed, begin, end, oldPresent}:
      KLambda{name, id, quant, kids, removed, begin, end, present}
    case KLiteral{kind, number, text, begin, end}: t
''';f.write_text(s)
f=p/'src/front/families.bend';s=f.read_text();old='f_flat(f_scope_body(kid(t, 0), Con{v, env}, book), [kt_span("Var", nm(v), ix(v), qt(v), Nil{}, kb(v), ke(v))])';assert s.count(old)==1;s=s.replace(old,'k_lambda_presence('+old+', f_eq(tg(t), "FLambda") || k_quantity_present(t))');f.write_text(s)
changes=[]
for f in p.rglob('*'):
 if f.is_file() and f.relative_to(p).parts[0] in ['src','tools']:
  old=parent/f.relative_to(p)
  if f.read_bytes()!=old.read_bytes():
   rel=str(f.relative_to(p));patch=out/(rel.replace('/','_')+'.patch');patch.write_text(''.join(difflib.unified_diff(old.read_text().splitlines(True),f.read_text().splitlines(True),fromfile='a/'+rel,tofile='b/'+rel)));changes.append({'path':rel,'parentSha256':hashlib.sha256(old.read_bytes()).hexdigest(),'sha256':hashlib.sha256(f.read_bytes()).hexdigest(),'patch':str(patch),'lineDelta':len(f.read_text().splitlines())-len(old.read_text().splitlines())})
(out/'manifest.json').write_text(json.dumps({'parent':str(parent),'project':str(p),'changes':changes,'netLines':sum(x['lineDelta'] for x in changes),'reason':'spans-lambda-direct-01 implicit-exists witness: preserve quantity presence through scope temporary Var'},indent=2)+'\n');c=json.loads((base/'workflow.json').read_text());c['project']=str(p);(out/'workflow.json').write_text(json.dumps(c,indent=2)+'\n');print(out)
