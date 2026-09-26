#!/usr/bin/env python3
"""Verify the installed release and exercise a manifest-driven relocated package."""
from pathlib import Path
import hashlib, json, os, shutil, subprocess, time
root=Path(__file__).resolve().parents[3];project=root/'selfhost';out=project/'build/phase7/s4/release-smoke-01';out.mkdir()
node='/home/ai/.nvm/versions/node/v24.18.0/bin/node';manifest=json.loads((project/'dist/release.json').read_text())
env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k!='NODE_OPTIONS'}
env.update(CC='/tmp/bend-s4-clang19/root/usr/lib/llvm-19/bin/clang',LD_LIBRARY_PATH='/tmp/bend-s4-clang19/root/usr/lib/x86_64-linux-gnu')
report={'complete':False,'pass':False,'releaseSha256':hashlib.sha256((project/'dist/release.json').read_bytes()).hexdigest(),'observations':[],'scope':'Installed default and relocated ordinary use with no upstream checkout in relocated package; no GPU or broad native claim.'}
def save(): (out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
def run(label,cwd,args,expected=None):
 row={'label':label,'cwd':str(cwd),'argv':[node,'--stack-size=4096',*args],'started':time.time()};report['observations'].append(row);save()
 with (out/(label+'.stdout')).open('x') as stdout,(out/(label+'.stderr')).open('x') as stderr:
  row['exitCode']=subprocess.run(row['argv'],cwd=cwd,env=env,stdout=stdout,stderr=stderr,timeout=180).returncode
 row.update(stdout=(out/(label+'.stdout')).read_text(),stderr=(out/(label+'.stderr')).read_text(),seconds=time.time()-row['started']);save()
 assert row['exitCode']==0 and row['stderr']=='',label
 if expected is not None:assert row['stdout']==expected,label
 else:assert json.loads(row['stdout'])['complete'] is True,label
try:
 run('installed-integrity',project,['tools/development/release.mjs','--verify'])
 relocated=out/'relocated';relocated.mkdir()
 extra=['dist/release.json','tools/development/release.mjs','tools/development/workflow.mjs','tools/development/equality.mjs','tools/development/process.mjs','tools/conformance/inventory.mjs']
 paths=sorted(set([x['path'] for x in manifest['files']+manifest['checkout']]+extra))
 for name in paths:
  assert not Path(name).is_absolute() and '..' not in Path(name).parts
  dst=relocated/name;dst.parent.mkdir(parents=True,exist_ok=True);shutil.copyfile(project/name,dst)
 report['relocationFiles']=[{'path':n,'sha256':hashlib.sha256((relocated/n).read_bytes()).hexdigest()} for n in paths];save()
 assert not (relocated/'.bootstrap').exists()
 fixture='import Base\n\ndef main() -> U32:\n  42\n#|42\n';(relocated/'smoke.bend').write_text(fixture)
 run('relocated-integrity',relocated,['tools/development/release.mjs','--verify'])
 for prefix,cwd,input in [('installed',project,'tests/conformance/typed-smoke/base-u32.bend'),('relocated',relocated,'smoke.bend')]:
  for label,flags,expected in [('check',['--check-only'],'All terms check.\n'),('interpreter',[],'42\n'),('javascript',['--run'],'42\n'),('native',['--run','--cpu'],'42\n')]:
   run(prefix+'-'+label,cwd,['cli.mjs',input,*flags],expected)
 run('relocated-final-integrity',relocated,['tools/development/release.mjs','--verify'])
 report['complete']=report['pass']=True
except Exception as error:report['error']=repr(error)
save();print(json.dumps({k:v for k,v in report.items() if k not in ['observations','relocationFiles']}));raise SystemExit(0 if report['pass'] else 1)
