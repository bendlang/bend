#!/usr/bin/env python3
"""Bounded policy-only controls; no compiler, fixture, archive or timing work."""
from pathlib import Path
import copy,hashlib,importlib.util,json,sys
here=Path(__file__).resolve().parent;out=Path(sys.argv[1]).resolve();out.mkdir(exist_ok=False)
policyfile=here/'review-additional-js-policy.py';spec=importlib.util.spec_from_file_location('additional_policy',policyfile);policy=importlib.util.module_from_spec(spec);spec.loader.exec_module(policy)
def ident(f):return {'file':str(f.resolve()),'sha256':hashlib.sha256(f.read_bytes()).hexdigest()}
p={'runtimeNodeArgs':['--stack-size=4096','--max-old-space-size=4096'],'hostProvenance':{'driverSha256':'a'*64,'adapterSha256':'b'*64}}
fixture={'id':'check/control.bend','negative':False,'main':True,'expected':'8'}
def setup(na=False):
 common={'status':'error' if na else 'ok','phase':'compile' if na else 'runtime','checked':True,'typeAccepted':True,'proofTrust':'not-assessed','kernelChecked':False,'exitCode':1 if na else 0}
 if na:common['diagnostic']="Error: main's type Type cannot be printed (a function, a Type, an erased or dependent field)"
 else:common.update(output='8\n',stdout='8\n',stderr='')
 left={'id':fixture['id'],'lane':'js','namespace':'check','negative':False,'failureKind':None,'status':'not-applicable' if na else 'pass','result':copy.deepcopy(common)}
 right=copy.deepcopy(left);right['result']['hostProvenance']=copy.deepcopy(p['hostProvenance'])
 if na:left['reason']=right['reason']='Upstream gate exempts unprintable main types from compiled execution.'
 else:
  left['evidence']=right['evidence']='checked-execution';left['result'].update(executionArgs=p['runtimeNodeArgs'].copy(),executionMode='js');right['result'].update(runtimeNodeArgs=p['runtimeNodeArgs'].copy(),signal=None,verdict=policy.BANNER)
 pair={'id':fixture['id'],'lane':'js','referenceVerdict':left['status'],'candidateVerdict':right['status'],'reference':copy.deepcopy(common),'candidate':copy.deepcopy(common),'exactAgreement':True,'semanticAgreement':True}
 return pair,left,right
report={'kind':'phase30-additional-js-policy-controls','complete':False,'pass':False,'inputs':[ident(Path(__file__)),ident(policyfile)],'cases':[]}
def save(): (out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
save();(out/'consumed-controls.py').write_bytes(Path(__file__).read_bytes())
def run(name,na,mutate,expected):
 pair,left,right=setup(na);mutate(pair,left,right);r=policy.observe(pair,left,right,fixture,p);report['cases'].append({'name':name,'expected':expected,'result':r});save();assert r['accepted']==expected,name
run('ordinary checked output',False,lambda *a:None,True);run('narrow NA',True,lambda *a:None,True)
for field,value in [('signal','SIGTERM'),('error','EPERM'),('reason','host failed')]:
 for na in [False,True]:run(('NA' if na else 'pass')+' shared '+field,na,lambda q,a,b,f=field,v=value:(a['result'].update({f:v}),b['result'].update({f:v})),False)
run('unknown shared result key',False,lambda q,a,b:(a['result'].update(extra=True),b['result'].update(extra=True)),False)
run('unknown shared row key',False,lambda q,a,b:(a.update(extra=True),b.update(extra=True)),False)
run('kernel flag JSON type mismatch',False,lambda q,a,b:b['result'].update(kernelChecked=0),False)
run('stdout mismatch projected pair still equal',False,lambda q,a,b:b['result'].update(stdout='9\n'),False)
run('stderr mismatch projected pair still equal',False,lambda q,a,b:b['result'].update(stderr='x'),False)
run('candidate host identity',False,lambda q,a,b:b['result']['hostProvenance'].update(driverSha256='c'*64),False)
run('candidate args',False,lambda q,a,b:b['result'].update(runtimeNodeArgs=[]),False)
run('reference mode',False,lambda q,a,b:a['result'].update(executionMode='native'),False)
run('extra verdict banner',False,lambda q,a,b:b['result'].update(verdict='SOME PROOFS FAIL'),False)
run('NA unrelated paired diagnostic',True,lambda q,a,b:(a['result'].update(diagnostic='Error: unknown name'),b['result'].update(diagnostic='Error: unknown name')),False)
run('NA unexpected shared stdout',True,lambda q,a,b:(a['result'].update(stdout=''),b['result'].update(stdout='')),False)
run('pair exact false',False,lambda q,a,b:q.update(exactAgreement=False),False)
run('paired raw mismatch',False,lambda q,a,b:q['candidate'].update(output='9\n'),False)
run('shared fixture verdict fail',False,lambda q,a,b:(q.update(referenceVerdict='fail',candidateVerdict='fail'),a.update(status='fail'),b.update(status='fail')),False)
report['complete']=report['pass']=True;(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');(out/'consumed-controls.py').write_bytes(Path(__file__).read_bytes());print(json.dumps({'complete':True,'pass':True,'cases':len(report['cases'])}))
