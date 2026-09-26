import hashlib,json,os,pathlib,subprocess,time
base=pathlib.Path('/tmp/bend-s4-clang19'); evidence=base/'evidence'; root=base/'root'
clang=root/'usr/lib/llvm-19/bin/clang'
env=os.environ.copy()
env['PATH']=str(clang.parent)+':'+str(root/'usr/bin')+':'+env['PATH']
env['LD_LIBRARY_PATH']=str(root/'usr/lib/x86_64-linux-gnu')
env['CC']=str(clang)
source=base/'smoke.c'
source.write_text('#include <stdint.h>\n#include <stdio.h>\nint main(void) {\n  const unsigned _BitInt(128) wide = ((unsigned _BitInt(128))1 << 100) + 42;\n  const uint64_t low = (uint64_t)wide;\n  if (low != 42 || (wide >> 100) != 1) return 1;\n  printf("clang-c-smoke:%llu\\n", (unsigned long long)low);\n  return 0;\n}\n')
rows=[]
for name,args in [
 ('clang-version',[str(clang),'--version']),
 ('clang-ldd',['ldd',str(clang)]),
 ('clang-resource-dir',[str(clang),'-print-resource-dir']),
 ('clang-smoke-compile',[str(clang),'-std=c11','-O2','-Wall','-Wextra','-Werror',str(source),'-o',str(base/'smoke')]),
 ('clang-smoke-run',[str(base/'smoke')])]:
 start=time.monotonic()
 with (evidence/(name+'.stdout')).open('wb') as out,(evidence/(name+'.stderr')).open('wb') as err:
  result=subprocess.run(args,env=env,stdout=out,stderr=err,timeout=30)
 rows.append({'name':name,'argv':args,'exit':result.returncode,'elapsedSeconds':time.monotonic()-start,'stdout':str(evidence/(name+'.stdout')),'stderr':str(evidence/(name+'.stderr'))})
 print(name,result.returncode,flush=True)
 (evidence/'verification.json').write_text(json.dumps({'complete':len(rows)==5 and all(r['exit']==0 for r in rows),'affinity':sorted(os.sched_getaffinity(0)),'nice':os.getpriority(os.PRIO_PROCESS,0),'environment':{k:env[k] for k in ['PATH','LD_LIBRARY_PATH','CC']},'commands':rows,'packageManifest':str(evidence/'package-manifest.json')},indent=2)+'\n')
 assert result.returncode==0,name
assert (evidence/'clang-smoke-run.stdout').read_text()=='clang-c-smoke:42\n'
assert 'not found' not in (evidence/'clang-ldd.stdout').read_text()
assert 'clang version 19.1.7' in (evidence/'clang-version.stdout').read_text()
x=json.loads((evidence/'verification.json').read_text())
x['smokeOutputVerified']=True
x['missingLibraries']=False
x['artifacts']=[{'path':str(p),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in [clang,source,base/'smoke']]
(evidence/'verification.json').write_text(json.dumps(x,indent=2)+'\n')
