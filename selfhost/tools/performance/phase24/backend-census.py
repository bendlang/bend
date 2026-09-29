#!/usr/bin/env python3
"""Bounded current-image acquisition through the unchanged selected harness."""
from pathlib import Path
import hashlib, json, os, shutil, subprocess, sys, tarfile, time

ROOT = Path(__file__).resolve().parents[4]
SH = ROOT / 'selfhost'
NODE = Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
PIN = '018751270e800bc222a93dad7f257083ee53a5f7'
API = '5596f914fd245a5085a614b81099360aeaf601ed61f16357fc491c85106c1102'
def sha(p): return hashlib.sha256(Path(p).read_bytes()).hexdigest()
def save(p, value): Path(p).write_text(json.dumps(value, indent=2)+'\n')
def identity(p): return {'file':str(Path(p).resolve()), 'sha256':sha(p)}
def size(p): return sum(f.stat().st_size for f in Path(p).rglob('*') if f.is_file())

def plan(out, inv):
    out.mkdir()
    data=json.loads(inv.read_text()); assert data['revision']==PIN
    positives=[t for t in data['tests'] if not t['negative'] and t['main']]
    boundaries=[t for t in data['tests'] if t['failureKind']=='error']
    pilot=[]
    for ns in sorted({t['namespace'] for t in positives}):
        choices=[t for t in positives if t['namespace']==ns and t['bytes']<=2500]
        if not choices: choices=[t for t in positives if t['namespace']==ns]
        pilot.append(choices[len(choices)//2])
    lanes=lambda t:['interpreter']+(['js'] if 'js' in t['backends'] else [])+(['native'] if 'c' in t['backends'] else [])
    selected=[]
    for lane in ['check','interpreter','js','native']:
        cases=[{'id':t['id'],'lanes':[lane]} for t in boundaries if lane=='check' or lane in lanes(t)]
        if cases:selected.append({'name':'boundary-'+lane,'cases':cases,'retain':'all'})
    for lane in ['interpreter','js','native']:
        cases=[{'id':t['id'],'lanes':[lane]} for t in pilot if lane in lanes(t)]
        if cases:selected.append({'name':'pilot-'+lane,'cases':cases,'retain':'all'})
    consumed={(c['id'],c['lanes'][0]) for b in selected for c in b['cases']}
    broad=[]
    for lane in ['interpreter','js','native']:
        cases=[{'id':t['id'],'lanes':[lane]} for t in positives if lane in lanes(t) and (t['id'],lane) not in consumed]
        for i in range(0,len(cases),64):broad.append({'name':f'{lane}-{i//64:03d}','cases':cases[i:i+64],'retain':'failed'})
    p={'kind':'phase24-backend-census-plan','apiSha256':API,'pin':PIN,'inventory':identity(inv),'design':identity(ROOT/'design/phase24/backend-census.md'),'tool':identity(__file__),'cpu':'3-6','jobs':4,'timeoutMs':30000,'heapMb':4096,'stackKb':4096,'positiveRows':sum(len(lanes(t)) for t in positives),'boundaryRows':sum(len(lanes(t))+1 for t in boundaries),'pilot':selected,'broad':broad}
    shutil.copy2(__file__,out/'consumed-tool.py');save(out/'plan.json',p)
    print(json.dumps({'pilotRows':sum(len(b['cases']) for b in selected),'broadRows':sum(len(b['cases']) for b in broad),'batches':len(broad)}))

def archive(out, selected):
    expected={str(f.relative_to(selected)):sha(f) for f in selected.rglob('*') if f.is_file()}
    target=out/'selected.tar.gz'
    with tarfile.open(target,'w:gz',compresslevel=1) as tar:tar.add(selected,arcname='selected')
    actual={}
    with tarfile.open(target,'r:gz') as tar:
        for m in tar:
            if m.isfile(): actual[str(Path(m.name).relative_to('selected'))]=hashlib.sha256(tar.extractfile(m).read()).hexdigest()
    assert actual==expected, 'Archive roundtrip mismatch'
    save(out/'archive.json',{'archive':identity(target),'files':expected,'verifiedFiles':len(expected),'uncompressedBytes':size(selected),'method':'Every regular file SHA256 verified by reading back the compressed tar before removing only its new duplicate tree.'})
    shutil.rmtree(selected)

def run(planfile, kind, index, out, attempt=None):
    p=json.loads(planfile.read_text());batch=p[kind][index]
    batch['cases']=[{**c,**({'file':str((planfile.parent/c['file']).resolve())} if 'file' in c else {})} for c in batch['cases']]
    out.mkdir();shutil.copy2(__file__,out/'consumed-tool.py')
    if attempt:
        def verify():
            code="import {pathToFileURL} from 'node:url';import fs from 'node:fs';const a=JSON.parse(fs.readFileSync(process.argv[1]+'/attempt.json'));const {verifyAttempt}=await import(pathToFileURL(a.snapshot.root+'/tools/development/workflow.mjs'));await verifyAttempt(process.argv[1]);"
            with (out/'verification.log').open('a') as log:
                subprocess.run(['taskset','-c','3-6',str(NODE),'--input-type=module','-e',code,str(attempt)],stdout=log,stderr=log,check=True,timeout=30)
        verify();m=json.loads((attempt/'attempt.json').read_text())
        api=Path(m['api']['file']);runtime=Path(m['runtime']['file']);base=Path(m['base']['file']);host=Path(m['snapshot']['root'])
    else:
        assert sha(SH/'dist/typed-api.mjs')==API
        api=SH/'dist/typed-api.mjs';runtime=SH/'src/runtime.mjs';base=SH/'dist/base.bend';host=SH
    config={'upstream':str(SH/'.bootstrap/upstream-phase23'),'candidateAdapter':str(host/'tools/conformance/adapters/typed.mjs'),'cases':batch['cases'],'jobs':4,'workerMode':'isolated','timeoutMs':30000,'heapMb':4096,'stackKb':4096,'rssLimitMb':4096,'retain':batch['retain']}
    save(out/'config.json',config)
    env={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
    frozen=json.loads((SH/'build/phase16/wave6-backend-environment-01.json').read_text())
    env.update(frozen['environment']);env.update(BEND_TYPED_API=str(api),BEND_TYPED_RUNTIME=str(runtime),BEND_BASE=str(base),BEND_TYPED_TRACE='')
    inputs=[identity(planfile),identity(__file__),identity(NODE),identity(attempt/'attempt.json' if attempt else SH/'dist/release.json'),identity(api),identity(base),identity(runtime),identity(host/'tools/conformance/target.mjs'),identity(Path(env['CC']).resolve())]
    command=['taskset','-c','3-6',str(NODE),str(host/'tools/conformance/target.mjs'),str(out/'config.json'),str(out/'selected')]
    report={'kind':'phase24-backend-census-batch','batch':batch['name'],'inputs':inputs,'command':command,'environment':{k:env[k] for k in list(frozen['environment'])+['BEND_TYPED_API','BEND_TYPED_RUNTIME','BEND_BASE','BEND_TYPED_TRACE']},'complete':False,'rowsExpected':len(batch['cases']),'started':time.time()};save(out/'report.json',report)
    start=time.monotonic()
    try:
        with (out/'stdout.log').open('w') as a,(out/'stderr.log').open('w') as b:child=subprocess.run(command,cwd=SH,env=env,stdout=a,stderr=b,timeout=420)
        report['exitCode']=child.returncode;report['wallSeconds']=time.monotonic()-start
        selected=out/'selected';paired=json.loads((selected/'paired.json').read_text())
        assert not paired.get('error'),paired.get('error')
        assert len(paired['rows'])==len(batch['cases']) and not paired['missing']
        sides={n:json.loads((selected/(n+'.json')).read_text()) for n in ['reference','candidate']}
        for name,data in sides.items():
            assert data['finished'] and len(data['results'])==len(batch['cases'])
            assert not data['changedInputs'] and not data['identity']['changedArtifacts'] and not data['identity']['adapterChangedDuringRun']
        report.update(complete=True,rows=paired['rows'],exact=sum(r['exactAgreement'] for r in paired['rows']),rawSelectedComplete=paired['selectedComplete'],sideSummary={n:d['summary'] for n,d in sides.items()},sideResults={n:d['results'] for n,d in sides.items()})
        report['pass']=all(r['exactAgreement'] and r['candidateVerdict'] in ['pass','not-applicable'] and r['referenceVerdict'] in ['pass','not-applicable'] for r in paired['rows'])
        report['changedInputs']=[x for x in inputs if sha(x['file'])!=x['sha256']];assert not report['changedInputs']
        if attempt: verify()
        save(out/'report.json',report);archive(out,selected)
    except Exception as e:report['error']=str(e);report['wallSeconds']=time.monotonic()-start
    report['finished']=time.time();save(out/'report.json',report)
    print(json.dumps({k:report.get(k) for k in ['batch','complete','pass','exact','rowsExpected','wallSeconds','error']}))

if sys.argv[1]=='plan':plan(Path(sys.argv[2]).resolve(),Path(sys.argv[3]).resolve())
elif sys.argv[1] in ['run','candidate']:run(Path(sys.argv[2]).resolve(),sys.argv[3],int(sys.argv[4]),Path(sys.argv[5]).resolve(),Path(sys.argv[6]).resolve() if sys.argv[1]=='candidate' else None)
else:raise ValueError('Expected plan OUT INVENTORY or run PLAN pilot|broad INDEX OUT')
