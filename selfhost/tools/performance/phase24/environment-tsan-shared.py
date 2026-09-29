#!/usr/bin/env python3
"""Instrument saved, untouched Phase23 Bend C with the verified Clang16 TSan."""
import importlib.util,json,os,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]
helper=Path(__file__).with_name('environment-tsan.py')
spec=importlib.util.spec_from_file_location('environment_tsan',helper);api=importlib.util.module_from_spec(spec);spec.loader.exec_module(api)
identity,run=api.identity,api.run
def main():
 os.sched_setaffinity(0,{7});out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
 capfile=ROOT/'selfhost/build/phase24/backend-tsan-capability-01/report.json';cap=json.loads(capfile.read_text());assert cap['capabilityPass']
 for row in cap['runtimeMembers']:assert identity(Path(row['file']))==row
 manifest=ROOT/'implementation/phase23/evidence/manifest.json';members={r['path']:r for r in json.loads(manifest.read_text())['members']}
 inputs={str(p):identity(p) for p in [Path(__file__).resolve(),helper,capfile,manifest]}
 env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k!='TSAN_OPTIONS'};env.update(cap['environment'])
 old=ROOT/'selfhost/build/phase1/clang/root';rows=[]
 for index,name in [('5','array_atomic_fadd')]:
  observations=[]
  for side in ['reference','candidate']:
   directory=ROOT/'selfhost/build/phase23/backend-retained-arrays-01/selected'/f'{side}.json.artifacts'/index
   source=directory/(name+'.c');request=directory/'request.json'
   for path in [source,request]:
    inputs[str(path)]=identity(path);assert members[str(path.relative_to(ROOT))]['sha256']==inputs[str(path)]['sha256']
   req=json.loads(request.read_text());fixture=Path(req['test']['file']);inputs[str(fixture)]=identity(fixture);assert inputs[str(fixture)]['sha256']==req['test']['sha256']
   expected=req['test']['expected']+'\n';binary=out/(name+'-'+side)
   argv=[cap['environment']['CC'],'-std=c11','-g','-O1','-pthread','-fsanitize=thread','-fPIE','-pie','-resource-dir='+cap['resourceDir'],'-isystem',str(old/'usr/lib/llvm-16/lib/clang/16/include'),str(source),'-lm','-o',str(binary)]
   compilation=run(argv,out,env,timeout=60);row={'side':side,'source':inputs[str(source)],'request':inputs[str(request)],'compile':compilation,'expected':expected}
   if compilation['exitCode']==0 and not compilation['timedOut']:
    row['executable']=identity(binary);row['execution']=run([str(binary),'--threads','2'],out,env,timeout=30)
    x=row['execution'];row['oraclePass']=x['exitCode']==0 and not x['timedOut'] and x['stdout']==expected
    row['dataRaceReported']='WARNING: ThreadSanitizer: data race' in x['stderr'];row['sanitizerPass']=row['oraclePass'] and not x['stderr']
   observations.append(row)
  rows.append({'fixture':name,'observations':observations})
 changed=[file for file,row in inputs.items() if identity(Path(file))!=row]
 report={'kind':'phase24-preserved-bend-shared-tsan','complete':True,'pass':not changed and all(o.get('sanitizerPass',False) for r in rows for o in r['observations']),'cpu':[7],'workerThreads':2,'runtimeCapability':identity(capfile),'environment':cap['environment'],'instrumentation':'Unmodified preserved C, Clang16 -O1 -g -pthread -fsanitize=thread -fPIE -pie; no suppression.','scope':'Two bounded shared-atomic executions of previously checked emitted programs; no compiler rebuild, performance comparison or general race-freedom claim.','inputs':list(inputs.values()),'changedInputs':changed,'rows':rows}
 (out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({'pass':report['pass'],'rows':rows},indent=2))
if __name__=='__main__':main()
