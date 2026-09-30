#!/usr/bin/env python3
"""Fresh checked17 local-data ablations; no compiler or public-body mutation."""
from pathlib import Path
import argparse, hashlib, importlib.util, json, re, shutil
HERE=Path(__file__).resolve().parent; ROOT=HERE.parents[3]; OLD=HERE.parent/'phase30'
def load(name,file):
 s=importlib.util.spec_from_file_location(name,file); m=importlib.util.module_from_spec(s);s.loader.exec_module(m);return m
row=load('phase31_row',OLD/'prototype-owned-derive.py')
native=load('phase31_native',OLD/'prototype-owned-native-derive.py')
parser=row.parser
parser.ARITIES.update({'gen':4,'init':3,'prng':1})
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return dict(file=str(p),sha256=hashlib.sha256(b).hexdigest(),bytes=len(b))
def save(p,x):p.write_text(json.dumps(x,indent=2)+'\n')
def edit(s,a,b):
 assert s.count(a)==1,a;return s.replace(a,b)
def setup(text):
 prng=row.definition(text,'prng'); body=parser.callback(prng,'fn(1,function(a){'); assert len(body['params'])==1
 # Each original setup successor calculates its primitive arguments before the
 # non-tail setter; its result is forced before transferring to the next step.
 gen=row.definition(text,'gen');init=row.definition(text,'init')
 assert gen.count('get(G,"Array.set")')==1 and gen.count('get(G,"prng")')==1
 assert init.count('get(G,"Array.set")')==1
 helpers='function $Owned_prng('+body['params'][0]+'){return '+body['expr']+';}\n'+'''function $Owned_gen(n,i,seed,a){
 for(;n!==0n;){const oldN=n,oldI=i,oldSeed=seed,oldA=a;
  const nextSeed=force($Owned_prng(oldSeed));
  const nextN=oldN-1n,nextI=(oldI+1)>>>0;
  const nextA=force($Owned_native_set(null,oldA,oldI,(nextSeed&3)>>>0));
  n=nextN;i=nextI;seed=nextSeed;a=nextA;
 }return a;
}
function $Owned_init(n,i,a){
 for(;n!==0n;){const oldN=n,oldI=i,oldA=a;
  const nextN=oldN-1n,nextI=(oldI+1)>>>0;
  const nextA=force($Owned_native_set(null,oldA,oldI,oldI));
  n=nextN;i=nextI;a=nextA;
 }return a;
}
'''
 probe=row.definition(text,'row.probe'); before,fast=probe.split('/* owned row entry */',1);fast,after=fast.split('/* owned row generic */',1)
 fast=row.direct(fast,['gen','init'])
 assert not any('get(G,"'+n+'")' in fast for n in ['gen','init','prng'])
 result=edit(text,probe,before+'/* owned row entry */'+fast+'/* owned row generic */'+after)
 result=edit(result,'const $Owned_guards=',helpers+'const $Owned_guards=')
 return result,dict(originalPrng=prng,originalGen=gen,originalInit=init,helpers=helpers,probeBefore=probe,probeAfter=row.definition(result,'row.probe'))
def dp_shell(text):
 lines=text.splitlines(); arm=next(l for l in lines if l.startswith('function $Owned_cell_f4_fields('))
 at=arm.index('build("Dp",');left=at+len('build("Dp",');end=parser.close(arm,at+len('build'))
 # Preserve the exact ordered thunk vector, including its deferred setter.
 thunks=arm[left:end]; assert thunks.startswith('[') and thunks.endswith(']') and thunks.count('()=>')==4
 changed_arm=arm[:at]+thunks+arm[end+1:]
 result=edit(text,arm,changed_arm)
 start=text.index('function $Owned_row(');brace=text.index('{',start);end=parser.close(text,brace)+1;old=text[start:end]
 zero='return callOwned(callOwned(callOwned(callOwned(get(G,"row"),[0n]),[j]),[ai]),[state]);'
 assert zero in old
 changed='''function $Owned_row(n,j,ai,state){
 if(n!==0n){
  let fields=project("Dp",state).slice();
  for(;n!==0n;){const oldN=n,oldJ=j,oldAi=ai,oldFields=fields;
   const nextN=oldN-1n,nextJ=(oldJ+1)>>>0;
   const pending=$Owned_cell_fields(oldJ,oldAi,oldFields),values=[];
   for(let k=0;k<pending.length;k++)values.push(force(pending[k]()));
   n=nextN;j=nextJ;ai=oldAi;fields=values;
  }
  state=ctor("Dp",fields);
 }
 '''+zero+'\n}'
 result=edit(result,old,changed)
 return result,dict(originalArm=arm,replacementArm=changed_arm,exactThunkVector=thunks,originalRow=old,replacementRow=changed)
def main():
 p=argparse.ArgumentParser();p.add_argument('source',type=Path);p.add_argument('out',type=Path);a=p.parse_args();a.source=a.source.resolve();a.out=a.out.resolve();a.out.mkdir(parents=True,exist_ok=False)
 design=ROOT/'design/phase31/local-data-ladder.md'; inputs=[Path(__file__),design,OLD/'prototype-owned-derive.py',OLD/'prototype-owned-native-derive.py',OLD/'inspect-terminal-region.py']
 for n in ['candidate.mjs','candidate.mjs.json','upstream.mjs','upstream.mjs.json','row.bend']:inputs.append(a.source/n)
 record=dict(kind='phase31-local-data-derivation',complete=False,inputs=[ident(x)for x in inputs],variants={},rewrites={});save(a.out/'derive.json',record)
 try:
  receipt=json.loads((a.source/'candidate.mjs.json').read_text());ts=json.loads((a.source/'upstream.mjs.json').read_text())
  assert receipt['complete'] and receipt['observation']['checked'] and ts['complete'] and ts['checked']
  assert receipt['api']['sha256']=='33545640e25beffb61639b27f4815aaeb345fda14758e1d63418cd1d0ccc0637'
  assert receipt['runtime']['sha256']=='6731308bcddc6faf68d0f2f9988b1299d4d62069fa091e94857f56bded44b3d6'
  assert receipt['input']['sha256']==ts['input']['sha256']==ident(a.source/'row.bend')['sha256']
  base=(a.source/'candidate.mjs').read_text();upstream=(a.source/'upstream.mjs').read_text()
  assert ident(a.source/'candidate.mjs')['sha256']==receipt['output']['sha256'];assert ident(a.source/'upstream.mjs')['sha256']==ts['output']['sha256']
  prior,record['rewrites']['row']=row.derive(base,'private_row')
  direct,record['rewrites']['native']=native.derive(prior)
  stagea,record['rewrites']['setup']=setup(direct)
  stageb,record['rewrites']['dp_shell']=dp_shell(stagea)
  sources=dict(baseline=base,private_native=direct,private_setup=stagea,private_dp=stageb,typescript=upstream)
  public=[line for line in base.splitlines()if line.startswith('G[')and not line.startswith('G["row.probe"]=')]
  for name,source in sources.items():
   if name!='typescript':
    for line in public:assert line in source.splitlines(),line
   target=a.out/(name+'.mjs');target.write_text(row.wrap(source,name=='typescript'));record['variants'][name]=ident(target)
  points=[dict(args=[n,seed],expected=row.oracle(n,seed))for n in [0,1,2,7,16,32,64]for seed in [0,1,17,4294967295]];save(a.out/'points.json',points)
  controls=(OLD/'prototype-owned-controls.mjs').read_text()
  controls=edit(controls,"const variants=['baseline','private_cell','private_scalar','private_row'];","const variants=['baseline','private_native','private_setup','private_dp'];")
  (a.out/'controls.mjs').write_text(controls);record['controls']=ident(a.out/'controls.mjs')
  shutil.copyfile(Path(__file__),a.out/'consumed-derive.py');shutil.copyfile(design,a.out/'design.md')
  record['complete']=True
 except Exception as e:record['error']=repr(e);raise
 finally:save(a.out/'derive.json',record)
 print(json.dumps(dict(complete=True,out=str(a.out))))
if __name__=='__main__':main()
