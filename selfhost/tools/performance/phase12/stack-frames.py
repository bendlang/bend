"""Diagnostic bytecode frame inspection; not execution or performance evidence."""
from pathlib import Path
import hashlib,json,subprocess
repo=Path(__file__).resolve().parents[4]
node=Path('/home/ai/.nvm/versions/node/v24.18.0/bin/node')
out=repo/'selfhost/build/phase12/stack-frames-01'
out.mkdir()
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
report={'kind':'phase12-bytecode-frame-diagnostic','complete':False,'hypothesis':'Inlining const-bearing branches may increase bytecode frame slots in deep non-tail recursive checker paths. Bytecode is diagnostic only; it does not establish optimized machine-stack size or causality.','inputs':[ident(Path(__file__)),ident(node)],'rows':[]}
(out/'consumed-tool.py').write_bytes(Path(__file__).read_bytes())
for name,api in [('phase11',repo/'selfhost/build/phase11/integrated-01/equality/api.mjs'),('integrated01',repo/'selfhost/build/phase12/integrated-01/equality/api.mjs')]:
 report['inputs'].append(ident(api))
 for fun in ['check','check_node','tele_check_static','tele_check_after_head','check_ctr_found','subst_terms','subst_node']:
  args=[str(node),'--no-lazy','--print-bytecode','--print-bytecode-filter=$'+fun+'$',str(api)]
  r=subprocess.run(args,capture_output=True,text=True,timeout=30)
  label=name+'-'+fun
  (out/(label+'.stdout')).write_text(r.stdout);(out/(label+'.stderr')).write_text(r.stderr)
  assert r.returncode==0,(label,r.returncode,r.stderr)
  report['rows'].append({'variant':name,'function':fun,'command':args,'exitCode':r.returncode,'stdout':ident(out/(label+'.stdout')),'stderr':ident(out/(label+'.stderr')),'metrics':[l for l in r.stdout.splitlines() if l.startswith(('Bytecode length:','Parameter count','Register count','Frame size'))]})
  (out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
for i in report['inputs']:assert ident(Path(i['file']))['sha256']==i['sha256']
report['complete']=True
(out/'report.json').write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps([{'variant':r['variant'],'function':r['function'],'metrics':r['metrics']} for r in report['rows']]))
