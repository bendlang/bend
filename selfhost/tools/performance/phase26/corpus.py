#!/usr/bin/env python3
"""Emit a new checked candidate and reuse hash-verified Phase25 oracle inputs."""
from pathlib import Path
import json, sys
TOOLS=Path(__file__).resolve().parent
sys.path.insert(0,str(TOOLS.parent/'phase25'))
from campaign import child, ident, save, verify, NODE

attempt,baseline,out=[Path(p).resolve() for p in sys.argv[1:]]
out.mkdir(parents=True,exist_ok=False)
metadata=TOOLS.parent/'phase25/corpus/metadata.json'
old=json.loads((baseline/'manifest.json').read_text())
assert old['complete']
cases=json.loads(metadata.read_text())
inputs=[ident(metadata),ident(TOOLS/'emit.mjs'),ident(Path(__file__)),ident(attempt/'attempt.json'),ident(baseline/'manifest.json'),ident(NODE),ident(TOOLS.parent/'phase25/execute.mjs'),ident(TOOLS.parent/'phase25/campaign.py')]
frozen={x['file']:x['sha256'] for x in old['inputs']}
assert ident(metadata)['sha256']==frozen[str(metadata)]
report={'kind':'phase26-corpus-regression','complete':False,'baselineManifest':ident(baseline/'manifest.json'),'inputs':inputs,'cases':[]}
save(out/'report.json',report)
for case in cases:
    source=TOOLS.parent/'phase25'/case['relativeFile']
    assert ident(source)['sha256']==frozen[str(source)]
    inputs.append(ident(source))
    directory=out/case['id'];directory.mkdir()
    row={'id':case['id'],'source':ident(source)};report['cases'].append(row)
    row['emission']=child([TOOLS/'emit.mjs',attempt,source,directory/'candidate.mjs'],directory/'emit',timeout=120)
    save(out/'report.json',report)
    assert row['emission']['complete'],case['id']+' emission failed'
    save(directory/'checks.json',{'exportName':case['exportName'],'inputs':case['correctness']})
    row['execution']=child([TOOLS.parent/'phase25/execute.mjs','check',directory/'candidate.mjs',directory/'checks.json'],directory/'check')
    save(out/'report.json',report)
    assert row['execution']['complete'],case['id']+' execution failed'
    row['oldModule']=ident(baseline/case['id']/'selfhost.mjs')
    row['referenceModule']=ident(baseline/case['id']/'upstream.mjs')
    inputs.extend([row['oldModule'],row['referenceModule'],row['emission']['result']['output']])
    for side,key in [('selfhost','oldModule'),('upstream','referenceModule')]:
        receipt=baseline/case['id']/(side+'.mjs.json');inputs.append(ident(receipt))
        prior=json.loads(receipt.read_text())
        assert prior['complete'] and prior['checked'] and prior['output']['sha256']==row[key]['sha256']
        assert prior['input']['sha256']==row['source']['sha256']
    save(out/'report.json',report)
verify(inputs)
report['complete']=True;report['observations']=sum(len(x['execution']['result']['results']) for x in report['cases'])
save(out/'report.json',report)
print(json.dumps({'complete':True,'libraries':len(cases),'observations':report['observations']}))
