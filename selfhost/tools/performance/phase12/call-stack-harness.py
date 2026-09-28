import json,os,subprocess,hashlib,sys
from pathlib import Path
root=Path.cwd();source=root/sys.argv[1];out=root/sys.argv[2];out.mkdir();node=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node');manifest=json.loads((source/'manifest.json').read_text());upstream=root/'selfhost/.bootstrap/upstream-phase8'
def identity(p):p=Path(p);return{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
report={'kind':'phase12-exact-harness-stack-ablation','complete':False,'inputs':[identity(__file__),identity(source/'manifest.json'),identity(upstream/'tests/check/string_literal_long.bend')],'rows':[],'scope':'Fresh isolated unchanged conformance workers, validated per-image Base caches from preceding probes, CPU3,4MiBstack4GiBheap, no hook. Not timing.'};save=lambda:(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');save()
for v in manifest['variants']:
 directory=out/v['name'];directory.mkdir();host=Path(v['host']).parent;output=directory/'observations.json';env={k:x for k,x in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']};env.update(BEND_TYPED_API=v['api']['file'],BEND_TYPED_RUNTIME=manifest['runtime']['file'],BEND_BASE=manifest['base']['file'],BEND_UPSTREAM=str(upstream),BEND_TYPED_TRACE='1');argv=['taskset','-c','3',str(node),str(host/'conformance/run.mjs'),'--upstream',str(upstream),'--adapter',str(host/'conformance/adapters/typed.mjs'),'--output',str(output),'--jobs','1','--timeout','30000','--worker-mode','isolated','--lanes','check','--filter','^check/string_literal_long\\.bend$','--stack-kb','4096','--heap-mb','4096','--retain','all','--selected-exit','1'];row={'variant':v['name'],'argv':argv,'env':{k:x for k,x in env.items() if k.startswith('BEND_')},'api':v['api']};report['rows'].append(row);save()
 try:
  r=subprocess.run(argv,cwd=root,env=env,capture_output=True,text=True,timeout=45);row['returncode']=r.returncode;(directory/'stdout').write_text(r.stdout);(directory/'stderr').write_text(r.stderr);assert r.returncode>=0;rpt=json.loads(output.read_text());assert len(rpt['results'])==1 and not rpt['changedInputs'];row['result']=rpt['results'][0];row['artifact']=identity(output);print(json.dumps({'variant':v['name'],'returncode':r.returncode,'result':row['result']}),flush=True)
 except BaseException as e:row['error']=repr(e);save();raise
 save()
report['complete']=True;save()
