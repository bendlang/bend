#!/usr/bin/env python3
"""Compare unchanged Phase23 TCP emissions on supported Bun/Node hosts."""
import hashlib,json,os,resource,signal,subprocess,sys,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]
def identity(p):return {'file':str(p),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
def main():
 out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
 os.sched_setaffinity(0,{7})
 bun=ROOT/'selfhost/build/phase24/backend-environment-01/bun-linux-x64-baseline/bun'
 assert identity(bun)['sha256']=='c01b9916c9632dff543b8c99a0a9bdc043e263853f05b6ed91ac9060a2fc08d2'
 node=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
 assert identity(node)['sha256']=='41a74efb34cbde5c7632cdac0cf8bd1a14d0b8d73dc1e82755014d9a9ce70f5c'
 inputs={str(p):identity(p) for p in [Path(__file__).resolve(),bun,node]};rows=[]
 env={k:v for k,v in os.environ.items() if not k.startswith(('BEND_','BUN_')) and k not in ['NODE_OPTIONS','NODE_PATH']}
 for dirname,stem in [('backend-final-new-01','tcp_recv_max_zero'),('backend-final-controls-01','tcp_zero_idle')]:
  selected=ROOT/'selfhost/build/phase23'/dirname/'selected';observations=[]
  for side,suffix in [('reference','cjs'),('candidate','mjs')]:
   directory=selected/f'{side}.json.artifacts/4';request=directory/'request.json';source=directory/f'{stem}.{suffix}'
   for p in [request,source,selected/f'{side}.json']:inputs[str(p)]=identity(p)
   req=json.loads(request.read_text());fixture=Path(req['test']['file']);inputs[str(fixture)]=identity(fixture)
   assert inputs[str(fixture)]['sha256']==req['test']['sha256']
   expected=req['test']['expected']+'\n';assert req['lane']=='js'
   argv=([str(bun),str(source)] if side=='reference' else [str(node),'--stack-size=4096','--max-old-space-size=4096',str(source)]);start=time.monotonic();proc=subprocess.Popen(argv,cwd=out,env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE,start_new_session=True)
   timed_out=False
   try:stdout,stderr=proc.communicate(timeout=30)
   except subprocess.TimeoutExpired:
    timed_out=True;os.killpg(proc.pid,signal.SIGKILL);stdout,stderr=proc.communicate()
   label=stem+'-'+side;(out/(label+'.stdout')).write_bytes(stdout);(out/(label+'.stderr')).write_bytes(stderr)
   row={'side':side,'source':inputs[str(source)],'request':inputs[str(request)],'argv':argv,'cwd':str(out),'timeoutMs':30000,'wallSeconds':time.monotonic()-start,'exitCode':proc.returncode,'timedOut':timed_out,'stdout':stdout.decode(),'stderr':stderr.decode(),'expected':expected,'oraclePass':not timed_out and proc.returncode==0 and stdout.decode()==expected and stderr==b''}
   observations.append(row)
  same=all(observations[0][k]==observations[1][k] for k in ['exitCode','timedOut','stdout','stderr'])
  rows.append({'fixture':stem,'observations':observations,'runtimeObservationsExact':same,'pass':same and all(r['oraclePass'] for r in observations)})
 changed=[str(p) for p,row in inputs.items() if identity(Path(p))!=row]
 report={'kind':'phase24-preserved-tcp-supported-host-ablation','complete':True,'pass':not changed and all(r['pass'] for r in rows),'scope':'New runtime execution observations of unchanged previously checked emissions; not new compilation, Node conformance, timing comparison or rewritten Phase23 results.','referenceRuntime':identity(bun),'candidateRuntime':identity(node),'cpu':[7],'stackRlimit':resource.getrlimit(resource.RLIMIT_STACK),'addressSpaceRlimit':resource.getrlimit(resource.RLIMIT_AS),'runtimeResourcePolicy':'Reference uses Bun defaults; candidate uses Node24 with original 4MiB stack and 4GiB heap. Runtime/resource differences are explicit, so this is output-oracle validation, not a controlled resource or speed comparison.','inputs':list(inputs.values()),'changedInputs':changed,'rows':rows}
 (out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({'pass':report['pass'],'rows':[{k:r[k] for k in ['fixture','runtimeObservationsExact','pass']} for r in rows]},indent=2))
if __name__=='__main__':main()
