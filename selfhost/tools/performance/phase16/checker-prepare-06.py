from pathlib import Path
import shutil,json,hashlib,difflib
root=Path.cwd();base=root/'selfhost';old=base/'build/phase16/checker-source-05/project';out=base/'build/phase16/checker-source-06';out.mkdir();shutil.copytree(old,out/'project');project=out/'project'
p=project/'src/check/specialize.bend';s=p.read_text()
a=s.index('@unsafe\ndef term_key(');b=s.index('@unsafe\ndef sp_keys(',a)
s=s[:a]+'''# Keys rebase binding identities but never include source positions. Names and
# quantities stay significant, matching the pinned syntax-key contract.
@unsafe
def term_key(
  +t: KTerm,
) -> String:
  sp_key_scope(t, Nil{}, 0)

@unsafe
def sp_key_node(+t: KTerm, +id: U32, +children: String) -> String:
  sp_key_string(tg(t)) ++ sp_key_string(nm(t)) ++ U32.show(id) ++ ":" ++ U32.show(qt(t)) ++ "[" ++ children ++ "][" ++ sp_name_keys(rm(t)) ++ "]"

@unsafe
def sp_key_scope(+t: KTerm, +env: List<&2,KPName>, +depth: U32) -> String:
  kc(String, String.eq(tg(t), "All"),
    u => sp_key_node(t, depth, sp_key_scope(kid(t, 0), env, depth) ++ sp_key_scope(kid(t, 1), Con{KPName{nm(t), ix(t), depth}, env}, U32.add(depth, 1))),
    u => kc(String, String.eq(tg(t), "Lam"),
      u => sp_key_node(t, depth, sp_key_terms(ks(t), Con{KPName{nm(t), ix(t), depth}, env}, U32.add(depth, 1))),
      u => kc(String, String.eq(tg(t), "Let"),
        u => sp_key_node(t, ix(t), sp_key_let(ks(t), env, env, depth, depth)),
        u => sp_key_node(t, kc(U32, String.eq(tg(t), "Var"), u => kp_index(env, ix(t)), u => kc(U32, String.eq(tg(t), "Ref") || String.eq(tg(t), "ADT") || String.eq(tg(t), "Ctr") || String.eq(tg(t), "Literal"), u => 0, u => ix(t))), sp_key_terms(ks(t), env, depth)))))

@unsafe
def sp_key_terms(+ts: List<&2,KTerm>, +env: List<&2,KPName>, +depth: U32) -> String:
  match ts:
    case Nil{}: ""
    case Con{h, rest}: sp_key_scope(h, env, depth) ++ sp_key_terms(rest, env, depth)

@unsafe
def sp_key_let(+ts: List<&2,KTerm>, +outer: List<&2,KPName>, +body: List<&2,KPName>, +depth: U32, +next: U32) -> String:
  match ts:
    case Nil{}: ""
    case Con{h, rest}:
      kc(String, String.eq(tg(h), "Bind"),
        u => sp_key_node(h, next, sp_key_terms(ks(h), outer, depth)) ++ sp_key_let(rest, outer, Con{KPName{nm(h), ix(h), next}, body}, depth, U32.add(next, 1)),
        u => sp_key_scope(h, body, next))

'''+s[b:]
p.write_text(s);name='src/check/specialize.bend';before=(old/name).read_bytes();after=p.read_bytes();changes=[{'file':name,'beforeSha256':hashlib.sha256(before).hexdigest(),'afterSha256':hashlib.sha256(after).hexdigest(),'physicalLineDelta':len(after.splitlines())-len(before.splitlines()),'byteDelta':len(after)-len(before)}]
(out/'src_check_specialize.bend.patch').write_text(''.join(difflib.unified_diff(before.decode().splitlines(True),after.decode().splitlines(True),fromfile=name,tofile=name)))
(out/'manifest.json').write_text(json.dumps({'kind':'phase16-template-scoped-memo-keys','parentSource':'checker-source-05','changes':changes,'toolSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'plan':str(root/'design/phase16/checker-memo-identity.md')},indent=2)+'\n');(out/'config.json').write_text(json.dumps({'project':str(project),'upstream':str(base/'.bootstrap/upstream-phase8'),'profile':'equality','cpu':'1','jobs':1},indent=2)+'\n');print(out)
