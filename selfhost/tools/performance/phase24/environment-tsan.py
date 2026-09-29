#!/usr/bin/env python3
"""Probe an official Clang16 TSan runtime without changing the old toolchain."""
import hashlib,json,os,signal,subprocess,sys,tarfile,time
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]
def identity(p):return {'file':str(p),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
def run(argv,directory,env,timeout=30):
 start=time.monotonic();p=subprocess.Popen(argv,cwd=directory,env=env,stdout=subprocess.PIPE,stderr=subprocess.PIPE,start_new_session=True);expired=False
 try:stdout,stderr=p.communicate(timeout=timeout)
 except subprocess.TimeoutExpired:
  expired=True;os.killpg(p.pid,signal.SIGKILL);stdout,stderr=p.communicate()
 return {'argv':argv,'exitCode':p.returncode,'timedOut':expired,'stdout':stdout.decode(),'stderr':stderr.decode(),'wallSeconds':time.monotonic()-start}
def main():
 os.sched_setaffinity(0,{7});out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
 depot=ROOT/'selfhost/build/phase24/backend-environment-01'
 # The official distribution remains reproducible by its verified URL/digest;
 # remove only this new external installer to keep runtime probes below150MB.
 archive=depot/'bun-linux-x64-baseline.zip'
 if archive.exists():
  row=identity(archive);download=json.loads((depot/'bun-baseline-download.json').read_text());assert row['sha256']==download['sha256']
  (out/'external-installer-disposal.json').write_text(json.dumps({'removed':row,'reason':'Unpacked external Bun is retained. Official fixed URL, size, SHA256 and executable identity remain recorded; free installer space for bounded TSan controls.'},indent=2)+'\n');archive.unlink()
 deb=depot/'libclang-rt-16-dev_16.0.6-15~deb11u2_amd64.deb';assert identity(deb)['sha256']=='3316ea4250dc2e8aa083b8f865f6cb70473ceb395983619960f55680dc01b183'
 selected=['libclang_rt.tsan-x86_64.a','libclang_rt.tsan-x86_64.a.syms','libclang_rt.tsan_cxx-x86_64.a','libclang_rt.tsan_cxx-x86_64.a.syms']
 runtime=out/'runtime';members=[];p=subprocess.Popen(['dpkg-deb','--fsys-tarfile',str(deb)],stdout=subprocess.PIPE,stderr=subprocess.PIPE)
 with tarfile.open(fileobj=p.stdout,mode='r|') as tar:
  for m in tar:
   if Path(m.name).name not in selected:continue
   assert m.isfile() and m.name.startswith('./usr/lib/llvm-16/lib/clang/16/lib/linux/')
   target=runtime/m.name;target.parent.mkdir(parents=True,exist_ok=True)
   with tar.extractfile(m) as source,target.open('xb') as dest:
    for block in iter(lambda:source.read(1024*1024),b''):dest.write(block)
   os.chmod(target,m.mode);members.append(identity(target))
 assert p.wait(timeout=10)==0 and len(members)==len(selected)
 old=ROOT/'selfhost/build/phase1/clang/root';resource=runtime/'usr/lib/llvm-16/lib/clang/16'
 env=os.environ.copy();frozen=json.loads((ROOT/'selfhost/build/phase16/wave6-backend-environment-01.json').read_text())['environment'];env.update(frozen);env.pop('TSAN_OPTIONS',None)
 source=out/'control.c';source.write_text('#include <pthread.h>\n#include <stdio.h>\n#include <stdatomic.h>\n#ifdef RACY\nvolatile int value;\n#define INC() (++value)\n#else\n_Atomic int value;\n#define INC() atomic_fetch_add(&value,1)\n#endif\nvoid *work(void *unused) { for(int i=0;i<10000;i++) INC(); return 0; }\nint main(void) { pthread_t t; if(pthread_create(&t,0,work,0)) return 2; work(0); pthread_join(t,0); printf("%d\\n",(int)value); return 0; }\n')
 results=[]
 for name in ['clean','racy']:
  executable=out/name;argv=[frozen['CC'],'-g','-O1','-pthread','-fsanitize=thread','-fPIE','-pie','-resource-dir='+str(resource),'-isystem',str(old/'usr/lib/llvm-16/lib/clang/16/include'),str(source),'-o',str(executable)]
  if name=='racy':argv.insert(1,'-DRACY=1')
  compile_result=run(argv,out,env);row={'name':name,'compile':compile_result}
  if compile_result['exitCode']==0:row.update(executable=identity(executable),execution=run([str(executable)],out,env))
  results.append(row)
 report={'kind':'phase24-clang16-tsan-capability','complete':True,'script':identity(Path(__file__).resolve()),'cpu':[7],'environment':frozen,'resourceDir':str(resource),'package':identity(deb),'runtimeMembers':members,'source':identity(source),'compiler':identity(Path(frozen['CC']).resolve()),'results':results,'scope':'Independent clean/racy pthread controls, not a generated Bend program sanitizer pass.'}
 report['capabilityPass']=len(results)==2 and results[0].get('execution',{}).get('exitCode')==0 and 'WARNING: ThreadSanitizer: data race' in results[1].get('execution',{}).get('stderr','')
 report['addedBytes']=sum(p.stat().st_size for d in [depot,out] for p in d.rglob('*') if p.is_file());assert report['addedBytes']<=150_000_000,report['addedBytes']
 (out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({'capabilityPass':report['capabilityPass'],'addedBytes':report['addedBytes'],'results':results},indent=2))
if __name__=='__main__':main()
