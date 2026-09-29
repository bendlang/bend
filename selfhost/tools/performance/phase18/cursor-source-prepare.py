#!/usr/bin/env python3
from pathlib import Path
import os,json,hashlib,shutil,stat,re,difflib
r=Path(__file__).resolve().parents[4];b=r/'selfhost/build/phase17/find-worker-source-01/project';a=r/'selfhost/build/phase17/find-worker-build-01';m=json.loads((a/'attempt.json').read_text());sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest();assert m['config']['project']==str(b);assert m['api']['sha256']=='9b20de5032e306a0b7ee2686a1cc79452f81fcb282ff6419a0d1ad5c4b5716b6';assert sha(Path(m['api']['file']))==m['api']['sha256']
for row in m['snapshot']['sources']:
 for side in ['original','frozen']:assert sha(Path(row[side]['file']))==row[side]['sha256']
def inv(root):
 rows=[]
 for base,dirs,files in os.walk(root,followlinks=False):
  for name in dirs+files:
   p=Path(base)/name;s=p.lstat();rel=str(p.relative_to(root))
   if p.is_symlink():rows.append({'file':rel,'kind':'symlink','target':os.readlink(p),'mode':stat.S_IMODE(s.st_mode)})
   elif p.is_file():rows.append({'file':rel,'kind':'file','bytes':s.st_size,'sha256':sha(p),'mode':stat.S_IMODE(s.st_mode)})
 return sorted(rows,key=lambda x:x['file'])
before=inv(b);o=r/'selfhost/build/phase18/cursor-source-01';o.mkdir();p=o/'project';shutil.copytree(b,p,symlinks=True);assert inv(p)==before
for f in (p/'src').rglob('*.bend'):
 if f.name=='lexer.bend':continue
 s=f.read_text();t=re.sub(r'List<&2,\s*FToken>', 'FInput',s)
 if s!=t:f.write_text(t)
f=p/'src/front/lexer.bend';s=f.read_text();names=['f_tx','f_tl','f_line','f_col','f_kind','f_skip','f_begin','f_end','f_previous_end','f_space']
for name in names:s=re.sub(r'\b'+name+r'\b',name.replace('f_','f_raw_',1),s)
s+='''
# Stage18 representation ablation: the shared context is inert.
type FCursorContext is Data:
  FCursorContext{serial: U32}
type FInput is Data:
  FInput{+tokens: List<&2,FToken>, +context: FCursorContext}

@unsafe
def f_input(+tokens: List<&2,FToken>) -> FInput:
  FInput{tokens, FCursorContext{0}}

@unsafe
def f_empty(+input: FInput) -> FInput:
  match input:
    case FInput{tokens, context}: FInput{Nil{}, context}

@unsafe
def f_prepend(+token: FToken, +input: FInput) -> FInput:
  match input:
    case FInput{tokens, context}: FInput{Con{token, tokens}, context}
'''
for name,result in [('f_tx','String'),('f_line','U32'),('f_col','U32'),('f_kind','U32'),('f_begin','U32'),('f_end','U32'),('f_previous_end','U32')]:
 s+='\n@unsafe\ndef '+name+'(+input: FInput) -> '+result+':\n  match input:\n    case FInput{tokens, context}: '+name.replace('f_','f_raw_',1)+'(tokens)\n'
s+='''
@unsafe
def f_tl(+input: FInput) -> FInput:
  match input:
    case FInput{tokens, context}:
      match tokens:
        case Nil{}: input
        case Con{token, rest}: FInput{rest, context}

@unsafe
def f_skip(+input: FInput) -> FInput:
  match input:
    case FInput{tokens, context}:
      f_choose(FInput, f_eq(f_raw_tx(tokens), "\\n") || f_eq(f_raw_tx(tokens), ";"),
        u => FInput{f_raw_skip(tokens), context}, u => input)

@unsafe
def f_space(+input: FInput) -> FInput:
  match input:
    case FInput{tokens, context}:
      f_choose(FInput, f_eq(f_raw_tx(tokens), "\\n"),
        u => FInput{f_raw_space(tokens), context}, u => input)
''';f.write_text(s)
def edit(rel,old,new):
 f=p/rel;s=f.read_text();assert s.count(old)==1,(rel,old,s.count(old));f.write_text(s.replace(old,new))
edit('src/front/declarations.bend','f_tops(f_lex(source, 1, 0, 0, Nil{}),','f_tops(f_input(f_lex(source, 1, 0, 0, Nil{})),')
edit('src/front/declarations.bend','f_tops(f_lex_indexed(start, source),','f_tops(f_input(f_lex_indexed(start, source)),')
edit('src/load/modules.bend','f_tops(f_lex_cursor(prefix, 1, 0, 0, Nil{}, start, start),','f_tops(f_input(f_lex_cursor(prefix, 1, 0, 0, Nil{}, start, start)),')
edit('src/load/modules.bend','f_tops(f_lex_cursor(body, line, 0, 0, Nil{}, f_cursor_add(start, offset), f_cursor_add(start, offset)),','f_tops(f_input(f_lex_cursor(body, line, 0, 0, Nil{}, f_cursor_add(start, offset), f_cursor_add(start, offset))),')
# Empty parser rests keep the exact input context. No lexical context is interpreted.
for rel,name,ctx in [('front/parser.bend','f_err','ts'),('front/parser.bend','f_atom_nat_start','ts'),('front/parser.bend','fpe_legacy','ts'),('front/parser.bend','fpe_span','start'),('front/parallel.bend','f_typed_let_try','old')]:
 f=p/'src'/rel;s=f.read_text();match=re.search(r'(?ms)^def '+name+r'\b.*?(?=^def |^law |\Z)',s);assert match
 body=match.group();old=', Nil{}}';assert body.count(old)==1,(name,body.count(old));new=body.replace(old,', f_empty('+ctx+')}');s=s[:match.start()]+new+s[match.end():];f.write_text(s)
# Replace explicit synthetic list splices with the same tokens plus inherited context.
edit('src/front/parser.bend','Con{FToken{"+", f_line(ts), f_col(ts), 0, f_begin(ts), f_cursor_add(f_begin(ts), 1), f_previous_end(ts)}, Con{FToken{"+", f_line(ts), U32.add(f_col(ts), 1), 0, f_cursor_add(f_begin(ts), 1), f_end(ts), f_cursor_add(f_begin(ts), 1)}, f_tl(ts)}}','f_prepend(FToken{"+", f_line(ts), f_col(ts), 0, f_begin(ts), f_cursor_add(f_begin(ts), 1), f_previous_end(ts)}, f_prepend(FToken{"+", f_line(ts), U32.add(f_col(ts), 1), 0, f_cursor_add(f_begin(ts), 1), f_end(ts), f_cursor_add(f_begin(ts), 1)}, f_tl(ts)))')
for rel,text,column,begin,previous in [('src/front/parser.bend','>','U32.add(f_col(ts), 1)','f_cursor_add(f_begin(ts), 1)','f_cursor_add(f_begin(ts), 1)'),('src/front/validate.bend','>','U32.add(f_col(ts), 1)','f_cursor_add(f_begin(ts), 1)','f_cursor_add(f_begin(ts), 1)'),('src/front/declarations.bend','-','U32.add(f_col(ts), 1)','f_cursor_add(f_begin(ts), 1)','f_cursor_add(f_begin(ts), 1)')]:
 token='FToken{"'+text+'", f_line(ts), '+column+', 0, '+begin+', f_end(ts), '+previous+'}'
 edit(rel,'Con{'+token+', f_tl(ts)}','f_prepend('+token+', f_tl(ts))')
edit('src/front/parser.bend','[FToken{"", f_line(ts), U32.add(f_col(ts), U32.from_nat(String.length(f_tx(ts)))), 0, f_end(ts), f_end(ts), f_end(ts)}]','f_prepend(FToken{"", f_line(ts), U32.add(f_col(ts), U32.from_nat(String.length(f_tx(ts)))), 0, f_end(ts), f_end(ts), f_end(ts)}, f_empty(ts))')
after=inv(p);old={x['file']:x for x in before};new={x['file']:x for x in after};assert old.keys()==new.keys();changed=[x for x in old if old[x]!=new[x]];expected=['src/front/declarations.bend','src/front/lexer.bend','src/front/literals_arrays.bend','src/front/parallel.bend','src/front/parser.bend','src/front/sugar.bend','src/front/validate.bend','src/load/imports.bend','src/load/modules.bend'];assert sorted(changed)==sorted(expected),changed;delta=[]
for rel in changed:
 x=(b/rel).read_text();y=(p/rel).read_text();(o/(rel.replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(x.splitlines(True),y.splitlines(True),fromfile='parent/'+rel,tofile='candidate/'+rel)));delta.append({'file':rel,'beforeSha256':sha(b/rel),'afterSha256':sha(p/rel),'lineDelta':len(y.splitlines())-len(x.splitlines()),'byteDelta':len(y.encode())-len(x.encode()),'definitionDelta':len(re.findall(r'^def ',y,re.M))-len(re.findall(r'^def ',x,re.M)),'typeDelta':len(re.findall(r'^type ',y,re.M))-len(re.findall(r'^type ',x,re.M))})
assert inv(b)==before;identity=lambda x:{'file':str(x),'sha256':sha(x)};(o/'manifest.json').write_text(json.dumps({'complete':True,'parent':str(b),'checkedParent':identity(a/'attempt.json'),'parentMembership':before,'candidateMembership':after,'changes':delta,'plan':identity(r/'design/phase18/cursor-representation.md'),'tool':identity(Path(__file__)),'controls':identity(r/'selfhost/build/phase18/cursor-controls-01/manifest.json')},indent=2)+'\n');shutil.copy2(__file__,o/'consumed-tool.py');shutil.copy2(r/'design/phase18/cursor-representation.md',o/'consumed-plan.md');(o/'workflow.json').write_text(json.dumps({'project':str(p),'upstream':str(r/'selfhost/.bootstrap/upstream-phase8'),'cpu':'3','jobs':1,'profile':'equality','timeoutMs':30000},indent=2)+'\n');print(o)
