from pathlib import Path
import hashlib,json
root=Path.cwd();source=root/'selfhost/build/phase16/checker-key-length-02/raw-keys.json';data=json.loads(source.read_text());out=root/'selfhost/build/phase16/checker-key-shape-01';out.mkdir()
def ident(p):return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
class Parser:
 def __init__(self,s):self.s=s;self.i=0
 def until(self,c):
  j=self.s.index(c,self.i);x=self.s[self.i:j];self.i=j+1;return x
 def string(self):
  n=int(self.until(':'));x=self.s[self.i:self.i+n];self.i+=n;return x
 def term(self):
  t={'tag':self.string(),'name':self.string(),'id':int(self.until(':')),'quant':int(self.until('['))};kids=[]
  while self.s[self.i]!=']':kids.append(self.term())
  self.i+=1;assert self.s[self.i]=='[';self.i+=1;removed=[]
  while self.s[self.i]!=']':removed.append(self.string())
  self.i+=1;t['kids']=kids;t['removed']=removed;return t
# This is a read-only structural comparison for the four constructors actually
# measured in grow_double, not a general compiler key implementation.
def lower(t,env=None,depth=0):
 env={} if env is None else env;k=t['tag'];n=t['name'];xs=t['kids'];assert not t['removed']
 if k=='Ref':
  assert not xs and t['quant']!=3
  return {'$':'Ref','k':n}
 if k=='Var':
  assert not xs and t['id'] in env
  return {'$':'Var','k':n,'i':env[t['id']]}
 if k=='Lam':
  assert len(xs)==1 and t['quant']==1
  return {'$':'Lam','k':n,'i':depth,'f':lower(xs[0],{**env,t['id']:depth},depth+1),'q':{'$':'Lone'}}
 if k=='App':
  assert len(xs)==2
  return {'$':'App','f':lower(xs[0],env,depth),'x':lower(xs[1],env,depth)}
 raise AssertionError(k)
rows=[]
for name in ['ordinal-only-05','scoped-key-06']:
 for ts,local in zip(data['typescript']['sequence'],data[name]['sequence']):
  assert ts['level']==local['level'];p=Parser(local['key']);t=p.term();assert p.i==len(p.s)
  projected=json.dumps(lower(t),separators=(',',':'),ensure_ascii=False)
  assert projected==ts['key'],(name,ts['level'])
  rows.append({'candidate':name,'level':ts['level'],'exactPinnedSyntaxProjection':True,'pinnedUtf16Length':len(projected),'localKeyLength':len(local['key'])})
report={'kind':'phase16-growth-key-structural-comparison','complete':True,'pass':True,'inputs':[ident(source),ident(Path(__file__))],'rows':rows,'scope':'Exact byte equality after readback for all eleven measured grow_double arguments and both local key encodings. Supports Var/Ref/App/Lam with explicit Lone lambda quantities only; not a general serializer or correctness claim for lost literal/optional-field information.'}
(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({'complete':True,'pass':True,'rows':len(rows)}))
