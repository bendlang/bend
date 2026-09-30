#!/usr/bin/env python3
"""Derive immutable Phase30 edit-distance call-only ablations. No timing."""
from pathlib import Path
import hashlib,json,re,sys
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]
def ident(p): return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,v):p.write_text(json.dumps(v,indent=2)+'\n')
def oracle(n,seed):
    size=1
    while size<=n:size*=2
    a=[(seed+i*5)&0xffffffff for i in range(size)]
    b=[((seed^((i*13)&0xffffffff))&3) for i in range(size)]
    prev=[((seed+i*17)&0xffffffff)%11 for i in range(size)]
    cur=[((seed+i*3)&0xffffffff)%7 for i in range(size)]
    ai=seed&3
    for j in range(n):cur[j+1]=min((prev[j+1]+1)&0xffffffff,(cur[j]+1)&0xffffffff,(prev[j]+int(ai!=b[j]))&0xffffffff)
    return json.dumps([a,b,cur,prev],separators=(',',':'))
def args(text):
    assert text[0]=='(' and text[-1]==')',text
    parts=[];at=1;level=0;quote=None;escaped=False
    for i,c in enumerate(text[1:-1],1):
        if quote:
            if escaped:escaped=False
            elif c=='\\':escaped=True
            elif c==quote:quote=None
        elif c in '\"\'`':quote=c
        elif c in '([{':level+=1
        elif c in ')]}':level-=1
        elif c==',' and level==0:parts.append(text[at:i]);at=i+1
    parts.append(text[at:-1]);return parts

def derive(source):
    generated=[];rewrites=[]
    for name in ['cell.f4','cell.f3','cell.f2','cell.f1','cell']:
        line=next(l for l in source.splitlines() if l.startswith(f'G["{name}"]=fn('))
        match=re.fullmatch(r'G\["'+re.escape(name)+r'"\]=fn\((\d+),function\(a\)\{(.*?)return matcher1\("(.*?)",\(\)=>fn\((\d+),function\(a\)\{(.*)\}\)\);\}\);',line)
        assert match,name
        count,lead,tag,k,body=match.groups();count=int(count);k=int(k)
        ids=re.findall(r'const (x\d+)=a\[\d+\];',lead);assert len(ids)==count
        private='P_'+name.replace('.','_');names=','.join(ids)
        generated.append(f'function {private}_original_fields({names},a){{{body}}}')
        if name!='cell.f4':
            begin=body.index('return jump(');assert body.endswith(');')
            first,last=args(body[begin+len('return jump'): -1]);assert first.startswith('call(')
            target,leading=args(first[4:]);target=re.fullmatch(r'get\(G,"(cell\.f[1-4])"\)',target).group(1)
            assert leading.startswith('[') and leading.endswith(']') and last.startswith('[') and last.endswith(']')
            new='return P_'+target.replace('.','_')+'('+leading[1:-1]+last[1:-1]+');'
            rewrites.append({'from':body[begin:],'to':new});body=body[:begin]+new
        generated.append(f'function {private}_fields({names},a){{{body}}}')
        invoke=f'{private}_original_fields({names},a)'
        generated.append(f'''function {private}({names},value){{
  const p=project({json.dumps(tag)},value);
  if(!p.length)return fn({k},a=>{invoke});
  const all=p.slice();
  if(all.length==={k})return {private}_fields({names},all);
  if(all.length<{k})return fn({k},a=>{invoke},null,all);
  let r={private}_original_fields({names},all.slice(0,{k}));
  if(all.length>{k})r=jump(force(r),all.slice({k}));
  return r;
}}''')
    old='call(call(get(G,"cell"),[x3530,x3531,]),[x3532])';new='force(P_cell(x3530,x3531,x3532))'
    assert source.count(old)==1
    source=source.replace(old,new)
    source+='\n// Disposable call-only prototype; public descriptors and helpers retained.\n'+'\n'.join(generated)+'\n'
    return source,rewrites+[{'from':old,'to':new}]

def wrap(source,upstream):
    assert source.count('export default ')==1
    source=source.replace('export default ','const originalExports = ',1)
    source+='''
function fixture(n,seed){
  let size=1;while(size<=n)size*=2;
  const a=Array.from({length:size},(_,i)=>(seed+i*5)>>>0);
  const b=Array.from({length:size},(_,i)=>((seed^(i*13))>>>0)&3);
  const prev=Array.from({length:size},(_,i)=>((seed+i*17)>>>0)%11);
  const cur=Array.from({length:size},(_,i)=>((seed+i*3)>>>0)%7);
'''
    if upstream:
        source+='  const st=originalExports.row(BigInt(n),0,seed&3,{$:"Dp",a,b,prev,cur});\n  return JSON.stringify([st.a,st.b,st.prev,st.cur]);\n'
    else:
        source+='  const st=originalExports.row(BigInt(n),0,seed&3,ctor("Dp",[... [a,b,prev,cur].map(array=>({array}))]));\n  return JSON.stringify(st.a.map(x=>x.array));\n'
    source+='}\nexport default {...originalExports,bench:fixture};\n'
    if not upstream:source+='export {P_cell,P_cell_f1,P_cell_f2,P_cell_f3,P_cell_f4};\n' if 'function P_cell(' in source else ''
    return source
out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
base=ROOT/'selfhost/build/phase29/transfer-04/editdist/candidate.mjs'
ts=ROOT/'selfhost/build/phase28/runtime-01/editdist/upstream.mjs'
source=ROOT/'selfhost/tools/performance/phase28/corpus/editdist.bend'
report={'kind':'phase30-edit-row-disposable-acquisition','complete':False,'scope':'Existing checked emissions plus identical host row fixture. Prototype changes private cell plumbing only; not a compiler version. No measurements.','inputs':[ident(p) for p in [Path(__file__),base,ts,source]],'variants':{}}
save(out/'report.json',report)
(out/'source.bend').write_bytes(source.read_bytes())
prototype,rewrites=derive(base.read_text());save(out/'rewrites.json',rewrites)
for name,text,upstream in [('unchanged',base.read_text(),False),('private',prototype,False),('upstream',ts.read_text(),True)]:
    path=out/(name+'.mjs');path.write_text(wrap(text,upstream));report['variants'][name]=ident(path)
points=[{'args':[n,s],'expected':oracle(n,s)} for n in [0,1,2,7,16,32,64] for s in [0,1,17,0xffffffff]]
save(out/'points.json',points)
for protocol in ['screen','confirm']:
    save(out/(protocol+'.json'),{'protocol':protocol,'inputs':[ident(source),ident(out/'points.json'),ident(out/'rewrites.json')], 'cases':[{'id':'edit-row-32','point':{'args':[32,17],'expected':oracle(32,17)},'modules':{k:v['file'] for k,v in report['variants'].items()}}]})
for p in report['inputs']:assert ident(Path(p['file']))==p
report.update(complete=True,points=ident(out/'points.json'),rewrites=ident(out/'rewrites.json'))
save(out/'report.json',report)
print(json.dumps(report))
