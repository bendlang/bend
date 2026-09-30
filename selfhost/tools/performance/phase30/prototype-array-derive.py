#!/usr/bin/env python3
"""Non-tail native-array helper ablations; no compilation or timing."""
from pathlib import Path
import hashlib,json,re,shutil,sys
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
base,out=map(lambda s:Path(s).resolve(),sys.argv[1:]);out.mkdir(parents=True,exist_ok=False)
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,v):p.write_text(json.dumps(v,indent=2)+'\n')
def close(text,start):
 level=0;quote=None;escape=False
 for at in range(start,len(text)):
  c=text[at]
  if quote:
   if escape:escape=False
   elif c=='\\':escape=True
   elif c==quote:quote=None
  elif c in '\"\'`':quote=c
  elif c in '([{':level+=1
  elif c in ')]}':
   level-=1
   if not level:return at+1
 raise ValueError('unbalanced expression')
guard='''
const A_function_prototype=Function.prototype;
const A_function_call=Object.getOwnPropertyDescriptor(A_function_prototype,"call").value;
function A_native(f,s){
 if(f!==s.f||Object.getPrototypeOf(f)!==Object.prototype)return false;
 for(const key of ["io","typeName"]){if(Object.getOwnPropertyDescriptor(f,key)||Object.getOwnPropertyDescriptor(Object.prototype,key))return false;}
 if(Object.getOwnPropertyDescriptor(s.code,"call")||Object.getPrototypeOf(s.code)!==A_function_prototype)return false;
 const invoke=Object.getOwnPropertyDescriptor(A_function_prototype,"call");
 if(!invoke||!Object.hasOwn(invoke,"value")||invoke.value!==A_function_call)return false;
 for(const [key,value]of [["arity",s.arity],["code",s.code],["env",null],["bound",s.bound]]){const d=Object.getOwnPropertyDescriptor(f,key);if(!d||!Object.hasOwn(d,"value")||d.value!==value)return false;}
 return Object.getOwnPropertyDescriptor(s.bound,"length").value===0;
}
const A_get_original=G["Array.get"],A_set_original=G["Array.set"];
const A_get_snapshot={f:A_get_original,code:A_get_original.code,arity:3,bound:A_get_original.bound};
const A_set_snapshot={f:A_set_original,code:A_set_original.code,arity:4,bound:A_set_original.bound};
'''
def derive(source,guarded):
 lines=source.splitlines(keepends=True);changes=[]
 for li,line in enumerate(lines):
  if not (line.startswith('G["cell') or line.startswith('function P_cell')):continue
  matches=list(re.finditer(r'call\(get\(G,"Array\.(get|set)"\),\[',line))
  for m in reversed(matches):
   end=close(line,m.start()+4);old=line[m.start():end]
   array_start=m.end()-1;array_end=close(line,array_start)
   assert array_end==end-1,old
   method=m.group(1);argtext=line[array_start+1:array_end-1]
   new=f'A_{method}(get(G,"Array.{method}"),'+argtext+')'
   line=line[:m.start()]+new+line[end:]
   changes.append({'line':li+1,'from':old,'to':new})
  lines[li]=line
 assert changes
 text=''.join(lines)+guard
 for method,params,actual,arity in [('get','t,a,i','a,i',3),('set','t,a,i,v','a,i,v',4)]:
  fallback=f'if(t!==null||!A_native(f,A_{method}_snapshot))return call(f,[{params}]);' if guarded else ''
  text+=f'function A_{method}(f,{params}){{{fallback}return force(array{method}({actual}));}}\n'
 text+='export {A_get,A_set};\n'
 return text,changes
report={'kind':'phase30-nontail-native-array-ablation','complete':False,'scope':'Generated JavaScript only. Non-tail Array.get/set sites in the cell chain; all jump sites and array helper implementations unchanged. Fixed variants assume unchanged native descriptors; guarded variants retain descriptor mutation/replacement fallback under the existing stable-host-builtin contract.','inputs':[ident(p) for p in [Path(__file__),base/'unchanged.mjs',base/'private.mjs',base/'points.json',ROOT/'design/phase30/native-array-call-ablation.md',ROOT/'design/phase30/native-array-tail-amendment.md']],'variants':{}}
save(out/'report.json',report)
for context in ['unchanged','private']:
 path=out/(context+'.mjs');shutil.copyfile(base/(context+'.mjs'),path);report['variants'][context]={'module':ident(path),'kind':'unchanged comparison bytes'}
 for mode in ['fixed','guarded']:
  name=context+'-array-'+mode;text,changes=derive(path.read_text(),mode=='guarded');p=out/(name+'.mjs');p.write_text(text)
  report['variants'][name]={'module':ident(p),'changes':changes,'kind':'disposable '+mode+' native-helper probe'}
shutil.copyfile(base/'points.json',out/'points.json')
point=next(p for p in json.loads((out/'points.json').read_text()) if p['args']==[32,17])
for protocol in ['screen','confirm']:save(out/(protocol+'.json'),{'protocol':protocol,'inputs':report['inputs'],'cases':[{'id':'nontail-array-row','point':point,'modules':{k:v['module']['file'] for k,v in report['variants'].items()}}]})
for p in report['inputs']:assert ident(Path(p['file']))==p
report['complete']=True;save(out/'report.json',report);print(json.dumps({'complete':True,'variants':{k:len(v.get('changes',[])) for k,v in report['variants'].items()}}))
