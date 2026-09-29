#!/usr/bin/env python3
from pathlib import Path
import json,hashlib
R=Path.cwd();out=R/'implementation/phase22/context-controls-marked-subset.json';assert not out.exists()
def ident(p):
 p=Path(p).resolve();b=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(b).hexdigest(),'bytes':len(b)}
old=R/'selfhost/build/phase16/marked-pattern-integrated-01/selected';new=R/'selfhost/build/phase22/context-group196-04/selected';inputs=[ident(__file__)]
def read(p):inputs.append(ident(p));return json.loads(p.read_text())
a=read(old/'paired.json');b=read(new/'paired.json');br={(x['id'],x['lane']):x for x in b['rows']};ar=read(old/'reference.json');nr=read(new/'reference.json');at={x['id']:x for x in ar['inventory']['tests']};bt={x['id']:x for x in nr['inventory']['tests']};fields=['file','sha256','expected','negative','failureKind','main'];rows=[]
assert len(a['rows'])==114 and len(b['rows'])==196 and not b['missing']
assert ar['inventory']['revision']==nr['inventory']['revision']=='b2111cf43244e65f76ddc278ee695e669f720cbf';assert ar['options']['upstream']==nr['options']['upstream']
for row in a['rows']:
 key=(row['id'],row['lane']);assert key in br and br[key]['exactAgreement'];assert row['reference']==br[key]['reference']
 for field in fields:assert at[row['id']].get(field)==bt[row['id']].get(field),(key,field)
 rows.append({'id':key[0],'lane':key[1],'historicalExact':row['exactAgreement'],'finalExact':True})
gate=read(new.parent/'report.json');assert gate['complete'];assert gate['api']['sha256']=='eac3b89d561287b9a51b411ab6353ea275e90c571de7d7c8e733c99eb0755a94'
report={'kind':'phase22-marked114-exact-subset-audit','complete':True,'pass':True,'api':gate['api'],'observations':114,'historicalExact':sum(x['historicalExact'] for x in rows),'finalExact':114,'closedHistoricalDifferences':sum(not x['historicalExact'] for x in rows),'rows':rows,'scope':'Read-only coverage audit of actual final196 results. Every original114 id/lane, fixture path/hash/oracle/main/negative field, pin revision/path and complete paired reference observation is identical. No standalone114 acquisition or rewritten oracle/status is claimed. Raw group196 pass:false remains preserved.','inputs':inputs}
assert report['historicalExact']==71 and report['closedHistoricalDifferences']==43
out.write_text(json.dumps(report,indent=2)+'\n');out.with_suffix('.md').write_text('''# Marked-pattern114 coverage

All114 historical observations are an exact subset of final source09's196-observation run, including all43 former differences. Their fixture paths, hashes, expected outcomes, negative/failure metadata, main settings, pin revision/path and actual pinned reference results are identical. Every corresponding final candidate row is exact.

This is a coverage audit of already acquired results, not a new standalone114 run. The old71-exact/43-difference report and the newer196 runner's raw failed selected-completion flag remain preserved.
''');print(json.dumps({'complete':True,'pass':True,'report':ident(out)}))
