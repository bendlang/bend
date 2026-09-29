#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,sys
R=Path.cwd();serial=sys.argv[1];out=R/f'implementation/phase22/context-controls-header-screen-{serial}.json';assert not out.exists()
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
file=R/f'selfhost/build/phase22/context-controls-header-screen-{serial}/report.json';r=json.loads(file.read_text());assert r['complete'] and r['pass'];inputs=[ident(__file__),ident(file)];parts=[];api=None
for job in r['jobs']:
 path=Path(job['report']['file']);assert ident(path)['sha256']==job['report']['sha256'];q=json.loads(path.read_text());assert q['complete'] and q['pass'] and q['selected']['exactDifferences']==0;assert not q['comparison']['lostExact'] and not q['comparison']['newPrimitiveMismatch']
 if api is None:api=q['api']
 assert q['api']==api
 parts.append({'name':job['name'],'observations':q['selected']['candidate']['probes'],'exactDifferences':0,'report':ident(path)})
 inputs.extend([ident(path),ident(path.parent/'selected/paired.json')])
 for item in [*q['inputs'],q['api'],q['attempt'],q['cache']]:assert ident(item['file'])['sha256']==item['sha256'],item['file']
assert sum(x['observations'] for x in parts)==58
report={'kind':'phase22-declaration-header-optimization-screen','complete':True,'pass':True,'api':api,'observations':58,'exact':58,'parts':parts,'scope':'Unchanged declaration/import26, alias4, header-demand2 and finalization26. Exact references and all-exact baseline outcomes preserved. The26 baseline rows are explicitly reused from acquired integration198; no fabricated baseline run or changed fixture/oracle. Correctness screen only; full integration, timing and selection remain separate.','inputs':inputs}
out.write_text(json.dumps(report,indent=2)+'\n');out.with_suffix('.md').write_text(f'''# Header optimization screen {serial}

All58 frozen observations match exactly: declaration/import26, alias4, header-demand2 and finalization26. No previously exact result or primitive behavior regressed. The26 declaration baseline is an explicitly labeled subset of the acquired integration198 vector, with unchanged full cases and complete paired rows.

This is a focused correctness screen for declaration-header guards. It makes no performance or promotion claim. Exact API: `{api['sha256']}`.
''');print(json.dumps({'complete':True,'pass':True,'report':ident(out)}))
