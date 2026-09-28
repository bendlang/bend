import json,os,subprocess,hashlib,sys
from pathlib import Path
root=Path.cwd();out=root/sys.argv[1];node=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node');manifest=json.loads((out/'manifest.json').read_text());fixture=root/'selfhost/.bootstrap/upstream-phase8/tests/check/string_literal_long.bend';worker=root/'selfhost/tools/performance/phase12/call-stack-worker.mjs'
report={'kind':'phase12-stack-regression-ablation-runs','complete':False,'rows':[],'scope':'Same fixture, checked source,4MiB stack,4GiB heap,CPU3. Raw stack hook adds one identical API frame; not timing.'};save=lambda:(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');save()
for variant in manifest['variants']:
 directory=out/variant['name'];result=directory/'observation.json';env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']};env.update(BEND_TYPED_API=variant['api']['file'],BEND_BASE=manifest['base']['file'],BEND_TYPED_RUNTIME=manifest['runtime']['file']);argv=['taskset','-c','3',str(node),'--stack-size=4096','--max-old-space-size=4096',str(worker),variant['api']['file'],variant['host'],str(fixture),str(result)];row={'variant':variant['name'],'argv':argv,'environment':{k:v for k,v in env.items() if k.startswith('BEND_')}};report['rows'].append(row);save()
 try:
  child=subprocess.run(argv,cwd=root,env=env,capture_output=True,text=True,timeout=90);row['returncode']=child.returncode;(directory/'stdout').write_text(child.stdout);(directory/'stderr').write_text(child.stderr);assert child.returncode==0,(child.returncode,child.stderr);observation=json.loads(result.read_text());assert observation['complete'];row['observation']=observation;print(json.dumps({'variant':variant['name'],'status':observation['observation']['status'],'diagnostic':observation['observation'].get('diagnostic'),'stacks':len(observation['stacks'])}),flush=True)
 except BaseException as e:row['error']=repr(e);save();raise
 save()
report['complete']=True;save()
