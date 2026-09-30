#!/usr/bin/env python3
"""Five serial fresh complete programs per side, preserving every stdout byte."""
from pathlib import Path
import hashlib,json,os,statistics,subprocess,sys,time
ENV={k:v for k,v in os.environ.items() if not k.startswith('BEND_') and k not in ['NODE_OPTIONS','NODE_PATH']}
config_path,out=[Path(p).resolve() for p in sys.argv[1:]]
config=json.loads(config_path.read_text())
assert config['samplesPerVariant']==5 and config['cpu']==3
assert config['stackKb']==4096 and config['heapMb']==1024 and config['timeoutSeconds']==120
assert set(config['variants'])=={'upstream','selfhost'}
out.mkdir(parents=True,exist_ok=False)
def ident(p):
    p=Path(p)
    return {'file':str(p.resolve()),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,data):p.write_text(json.dumps(data,indent=2)+'\n')
inputs=[ident(config_path),ident(Path(__file__)),ident(config['node']),*config['inputs']]
for variant in config['variants'].values():inputs.append(variant['program'])
def verify_inputs():
    for item in inputs:assert ident(item['file'])['sha256']==item['sha256'],item['file']
verify_inputs()
report={'kind':'phase28-application-process-timing','complete':False,'config':config,'inputs':inputs,'samples':[],'environmentPolicy':'Inherit parent environment except remove every BEND_* variable and NODE_OPTIONS/NODE_PATH; identical sanitized environment for both variants. No environment values are recorded.','timingScope':'Complete fresh process wall time: process spawn, Node startup, emitted program load, original computation, full stdout and process exit. Compilation excluded; no warm process reuse.'}
save(out/'report.json',report)
for index in range(5):
    order=['upstream','selfhost'] if index%2==0 else ['selfhost','upstream']
    for side in order:
        program=config['variants'][side]['program']['file']
        command=['taskset','-c','3',config['node'],'--stack-size=4096','--max-old-space-size=1024',program]
        row={'sample':index,'side':side,'command':command,'timeoutSeconds':120,'complete':False,'started':time.time()}
        begin=time.perf_counter()
        process=subprocess.Popen(command,env=ENV,stdout=subprocess.PIPE,stderr=subprocess.PIPE)
        try:stdout,stderr=process.communicate(timeout=120)
        except subprocess.TimeoutExpired:
            row['timeout']=True;process.kill();stdout,stderr=process.communicate()
        row['elapsedSeconds']=time.perf_counter()-begin
        row['finished']=time.time()
        row['returncode']=process.returncode
        stdout_file=out/f'{index:02d}-{side}.stdout';stderr_file=out/f'{index:02d}-{side}.stderr'
        stdout_file.write_bytes(stdout);stderr_file.write_bytes(stderr)
        row['stdout']=ident(stdout_file);row['stderr']=ident(stderr_file)
        row['exactStdout']=stdout==config['expectedStdout'].encode('utf-8')
        row['emptyStderr']=not stderr
        row['complete']=not row.get('timeout',False) and row['returncode']==0 and row['exactStdout'] and row['emptyStderr']
        report['samples'].append(row)
        save(out/f'{index:02d}-{side}.json',row);save(out/'report.json',report)
        print(json.dumps({'sample':index,'side':side,'complete':row['complete'],'processSeconds':row['elapsedSeconds']}),flush=True)
verify_inputs()
report['complete']=True
report['allSamplesValid']=all(row['complete'] for row in report['samples'])
if report['allSamplesValid']:
    report['summary']={}
    for side in ['upstream','selfhost']:
        values=[row['elapsedSeconds'] for row in report['samples'] if row['side']==side]
        report['summary'][side]={'samples':len(values),'medianSeconds':statistics.median(values),'minSeconds':min(values),'maxSeconds':max(values)}
    report['summary']['selfhostOverUpstream']=report['summary']['selfhost']['medianSeconds']/report['summary']['upstream']['medianSeconds']
save(out/'report.json',report)
