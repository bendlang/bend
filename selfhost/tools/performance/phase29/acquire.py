#!/usr/bin/env python3
"""Checked candidate emissions for selected unchanged Phase28 workloads."""
from pathlib import Path
import hashlib,json,os,subprocess,sys,time
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
sys.path.insert(0,str(HERE.parent/'phase25'))
from campaign import ident,save,verify,NODE,ENV,FLAGS
attempt,selection,out=map(lambda p:Path(p).resolve(),sys.argv[1:])
selected=json.loads(selection.read_text());out.mkdir(parents=True,exist_ok=False)
oldconfig=ROOT/'selfhost/build/phase28/timing-config.json'
oldreport=ROOT/'selfhost/build/phase28/timing-01/report.json'
prior=json.loads(oldreport.read_text());assert prior['complete'] and prior['allCasesMeasured']
known={v['file']:v['sha256'] for v in prior['inputs']}
cases={c['id']:c for c in json.loads(oldconfig.read_text())['cases']}
inputs=[ident(p) for p in [attempt/'attempt.json',selection,Path(__file__),HERE/'execute.mjs',HERE.parent/'phase26/emit.mjs',oldconfig,oldreport,NODE]]
report={'kind':'phase29-checked-transfer-acquisition','complete':False,'inputs':inputs,'cpu':5,'cases':[]}
save(out/'report.json',report)
def child(args,directory,timeout):
    directory.mkdir();command=['taskset','-c','5',str(NODE),*FLAGS,*map(str,args)]
    row={'command':command,'timeoutSeconds':timeout,'started':time.time(),'complete':False}
    save(directory/'launch.json',row);begin=time.monotonic()
    try:
        with (directory/'stdout.log').open('w') as stdout,(directory/'stderr.log').open('w') as stderr:
            p=subprocess.run(command,cwd=ROOT,env=ENV,stdout=stdout,stderr=stderr,timeout=timeout)
        row['exitCode']=p.returncode;lines=(directory/'stdout.log').read_text().splitlines()
        if lines:row['result']=json.loads(lines[-1])
        row['complete']=p.returncode==0 and row.get('result',{}).get('complete',False)
    except Exception as error:row['error']=str(error)
    row['processSeconds']=time.monotonic()-begin;save(directory/'launch.json',row);return row
for key in selected:
    case=cases[key];folder=out/key;folder.mkdir();source=ident(case['source']);inputs.append(source)
    for side,file in case['modules'].items():
        identity=ident(file);assert identity['sha256']==known[file];inputs.append(identity)
        receipt=Path(file+'.json');inputs.append(ident(receipt));r=json.loads(receipt.read_text())
        assert r['complete'] and (r.get('checked') or r.get('observation',{}).get('checked'))
        assert r['input']['sha256']==source['sha256'] and r['output']['sha256']==identity['sha256']
    point={k:case[k] for k in ['args','expected','exportName']};save(folder/'point.json',point)
    row={'id':key,'source':source,'point':point};report['cases'].append(row)
    row['emission']=child([HERE.parent/'phase26/emit.mjs',attempt,case['source'],folder/'candidate.mjs'],folder/'emission',120)
    save(out/'report.json',report)
    if row['emission']['complete']:
        row['check']=child([HERE/'execute.mjs','check',folder/'candidate.mjs',folder/'point.json'],folder/'check',120)
        row['modules']={'upstream':case['modules']['upstream'],'old':case['modules']['selfhost'],'candidate':str(folder/'candidate.mjs')}
    row['complete']=row['emission']['complete'] and row.get('check',{}).get('complete',False)
    save(out/'report.json',report);print(json.dumps({'id':key,'complete':row['complete']}),flush=True)
verify(inputs);report['complete']=all(c['complete'] for c in report['cases']);save(out/'report.json',report)
if report['complete']:
    config={'protocol':'transfer','inputs':[ident(out/'report.json'),*inputs],
            'cases':[{'id':c['id'],'point':c['point'],'modules':c['modules']} for c in report['cases']]}
    save(out/'timing-config.json',config)
raise SystemExit(0 if report['complete'] else 1)
