#!/usr/bin/env python3
"""Check source/output lineage for a frozen three-emitter timing configuration."""
from pathlib import Path
import hashlib,json,sys
config,out=map(Path,sys.argv[1:]);c=json.loads(config.read_text())
sha=lambda p:hashlib.sha256(Path(p).read_bytes()).hexdigest()
rows=[]
for case in c['cases']:
    row={'id':case['id'],'receipts':{},'moduleSha256':{}}
    sources=set()
    for variant,module in case['modules'].items():
        receipt=Path(module+'.json');r=json.loads(receipt.read_text())
        assert r['complete'] and (r.get('checked') or r['observation']['checked'])
        assert sha(module)==r['output']['sha256']
        assert sha(r['input']['file'])==r['input']['sha256']
        for field in ['api','runtime','base','driver']:
            if field in r:assert sha(r[field]['file'])==r[field]['sha256']
        sources.add(r['input']['sha256'])
        row['receipts'][variant]={'file':str(receipt),'sha256':sha(receipt),'api':r.get('api'),'runtime':r.get('runtime')}
        row['moduleSha256'][variant]=sha(module)
        if variant!='upstream':
            assert sha(c['runtimes'][variant])==r['runtime']['sha256']
    assert len(sources)==1
    row['sourceSha256']=sources.pop();rows.append(row)
assert not out.exists()
out.write_text(json.dumps({'complete':True,'configSha256':sha(config),'toolSha256':sha(__file__),'cases':rows},indent=2)+'\n')
