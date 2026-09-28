import json,os,subprocess,sys
from pathlib import Path
root=Path.cwd();out=root/sys.argv[1];manifest=json.loads((out/'manifest.json').read_text());node='/home/ai/.nvm/versions/node/v24.18.0/bin/node';report={'complete':False,'pass':False,'rows':[]};save=lambda:(out/'prime.json').write_text(json.dumps(report,indent=2)+'\n');save()
for v in manifest['variants']:
 env={k:x for k,x in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']};env.update(BEND_TYPED_API=v['api']['file'],BEND_TYPED_RUNTIME=manifest['runtime']['file'],BEND_BASE=manifest['base']['file']);argv=['taskset','-c','3',node,'--stack-size=4096','--max-old-space-size=4096',v['host'],'--prepare-base'];row={'variant':v['name'],'argv':argv,'env':{k:x for k,x in env.items() if k.startswith('BEND_')}};report['rows'].append(row);save()
 try:
  r=subprocess.run(argv,cwd=root,env=env,capture_output=True,text=True,timeout=90);row.update(returncode=r.returncode,stdout=r.stdout,stderr=r.stderr);assert r.returncode==0 and not r.stderr and r.stdout.startswith('Base checked by generated Bend API: ');save()
 except BaseException as e:row['error']=repr(e);save();raise
report.update({'complete':True,'pass':True});save()
