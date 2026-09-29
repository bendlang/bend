#!/usr/bin/env python3
"""Rerun preserved shared-atomic sanitizer executables on two physical cores."""
import importlib.util,json,os,sys
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]
helper=Path(__file__).with_name('environment-tsan.py')
spec=importlib.util.spec_from_file_location('environment_tsan',helper);api=importlib.util.module_from_spec(spec);spec.loader.exec_module(api)
def main():
 out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
 topology=[]
 for cpu in [2,3]:
  root=Path('/sys/devices/system/cpu')/('cpu'+str(cpu))/'topology'
  topology.append({'cpu':cpu,'physicalPackage':(root/'physical_package_id').read_text().strip(),'coreId':(root/'core_id').read_text().strip()})
 assert (topology[0]['physicalPackage'],topology[0]['coreId'])!=(topology[1]['physicalPackage'],topology[1]['coreId'])
 os.sched_setaffinity(0,{2,3});source=ROOT/'selfhost/build/phase24/backend-tsan-shared-01/report.json';old=json.loads(source.read_text());assert old['pass']
 env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k!='TSAN_OPTIONS'};env.update(old['environment']);rows=[]
 for previous in old['rows'][0]['observations']:
  executable=Path(previous['executable']['file']);assert api.identity(executable)==previous['executable']
  observed=api.run([str(executable),'--threads','2'],out,env,timeout=30)
  rows.append({'side':previous['side'],'executable':previous['executable'],'source':previous['source'],'expected':previous['expected'],'execution':observed,'pass':observed['exitCode']==0 and not observed['timedOut'] and observed['stdout']==previous['expected'] and not observed['stderr']})
 report={'kind':'phase24-shared-tsan-two-core-rerun','complete':True,'pass':all(r['pass'] for r in rows),'script':api.identity(Path(__file__).resolve()),'helper':api.identity(helper),'priorBuildAndSingleCoreReport':api.identity(source),'cpu':[2,3],'topology':topology,'workerThreads':2,'environment':old['environment'],'rows':rows,'scope':'Two new executions of unchanged sanitizer binaries on two distinct physical cores; no recompile, performance comparison or universal race-freedom claim.'}
 (out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report,indent=2))
if __name__=='__main__':main()
