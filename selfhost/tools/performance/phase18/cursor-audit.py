#!/usr/bin/env python3
from pathlib import Path
import json, hashlib, shutil, os, stat, re

r = Path(__file__).resolve().parents[4]
root = r/'selfhost/build/phase18'
out = root/'cursor-audit-01'; out.mkdir()
sha = lambda p: hashlib.sha256(p.read_bytes()).hexdigest()
ident = lambda p: {'file': str(p), 'sha256': sha(p)}
report = {'complete': False, 'pass': False, 'inputs': [ident(Path(__file__))]}
def read(p):
    report['inputs'].append(ident(p))
    return json.loads(p.read_text())
def save(): (out/'report.json').write_text(json.dumps(report, indent=2)+'\n')
def inventory(p):
    rows = []
    for base, dirs, files in os.walk(p, followlinks=False):
        for name in dirs+files:
            f = Path(base)/name; s = f.lstat(); rel = str(f.relative_to(p))
            if f.is_symlink(): rows.append({'file':rel,'kind':'symlink','target':os.readlink(f),'mode':stat.S_IMODE(s.st_mode)})
            elif f.is_file(): rows.append({'file':rel,'kind':'file','bytes':s.st_size,'sha256':sha(f),'mode':stat.S_IMODE(s.st_mode)})
    return sorted(rows, key=lambda x:x['file'])
def healthy(execution):
    assert execution['exitCode'] in [0,1]
    assert execution['error'] is None and execution['signal'] is None
    assert not execution['timedOut'] and not execution['overflow']
def source_cost(p):
    files = sorted((p/'src').rglob('*.bend')); texts = [f.read_text() for f in files]
    return {'modules':len(files),'physicalLines':sum(len(t.splitlines()) for t in texts),
        'nonblankLines':sum(sum(bool(s.strip()) for s in t.splitlines()) for t in texts),
        'bytes':sum(f.stat().st_size for f in files),
        'definitions':sum(len(re.findall(r'^def ',t,re.M)) for t in texts),
        'laws':sum(len(re.findall(r'^law ',t,re.M)) for t in texts),
        'types':sum(len(re.findall(r'^type ',t,re.M)) for t in texts)}
save()
try:
    old = read(root/'cursor-baseline-01/report.json'); new = read(root/'cursor-validation-01/report.json')
    for x in [old,new]:
        assert x['complete'] and x['healthPass'] and x['observations']==196
        assert x['reference']['selectedComplete']
        for phase in x['phases']: healthy(phase['execution'])
    a = read(root/'cursor-baseline-01/selected/paired.json')['rows']
    b = read(root/'cursor-validation-01/selected/paired.json')['rows']
    key = lambda x:(x['id'],x['lane'])
    aa={key(x):x for x in a}; bb={key(x):x for x in b}
    assert len(aa)==len(bb)==196 and aa.keys()==bb.keys()
    changes=[]
    for k,x in aa.items():
        y=bb[k]; assert x['reference']==y['reference'],k
        if x['candidate']!=y['candidate']: changes.append({'key':k,'before':x['candidate'],'after':y['candidate']})
    assert not changes, changes
    build=read(root/'cursor-build-01/build.json'); assert build['complete']
    for p in build['phases']: healthy(p['execution']); assert p['execution']['exitCode']==0
    focus=read(root/'cursor-build-01/validation-001/report.json'); assert focus['complete'] and focus['pass']
    direct=read(root/'cursor-direct-01/report.json'); assert direct['complete'] and direct['healthPass'] and direct['pass']; healthy(direct['execution'])
    detail=read(root/'cursor-direct-01/controls/report.json'); assert detail['complete'] and detail['pass'] and len(detail['controls'])==194
    allocations=read(root/'cursor-allocation-01/report.json'); assert allocations['complete'] and allocations['healthPass'] and allocations['pass']; healthy(allocations['execution'])
    m=read(root/'cursor-source-02/manifest.json'); project=root/'cursor-source-02/project'; parent=Path(m['parent'])
    assert inventory(parent)==m['parentMembership']; assert inventory(project)==m['candidateMembership']
    assert sha(root/'cursor-source-02/consumed-plan.md')==m['plan']['sha256']
    assert sha(Path(m['tool']['file']))==m['tool']['sha256']
    attempt=read(root/'cursor-build-01/attempt.json'); assert attempt['checked'] and attempt['artifactKind']=='derived-b1'
    assert attempt['config']['project']==str(project); assert sha(Path(attempt['api']['file']))==attempt['api']['sha256']
    for row in attempt['snapshot']['sources']:
        for side in ['original','frozen']: assert sha(Path(row[side]['file']))==row[side]['sha256']
    report.update({'complete':True,'pass':True,'rawOraclePass':new['pass'],
        'beforeExact':old['exact'],'afterExact':new['exact'],'observations':196,'changedOutcomes':changes,
        'knownStrictDifferences':196-new['exact'],'directControls':194,
        'sourceChanges':m['changes'],'sourceCost':{'parent':source_cost(parent),'candidate':source_cost(project)},
        'conceptDelta':{'types':2,'definitions':13,'description':'Inert context record and cursor wrapper; thirteen entry/read/movement adapters. No scope or grammar semantics.'},
        'allocationRows':allocations['rows'],'api':attempt['api']})
    report['families']={name:{'observations':len(rows),'exact':sum(x['exactAgreement'] for x in rows)}
        for name,rows in [('stage',[x for x in b if x['id'].startswith('rejected-stage/')]),
                         ('shape',[x for x in b if x['id'].startswith('group/')]),
                         ('pattern',[x for x in b if not x['id'].startswith(('rejected-stage/','group/'))])]}
    for x in report['inputs']: assert sha(Path(x['file']))==x['sha256']
except Exception:
    import traceback
    report['error']=traceback.format_exc()
shutil.copy2(__file__,out/'consumed-tool.py'); save()
print(json.dumps({k:v for k,v in report.items() if k not in ['inputs','sourceChanges','api']},indent=2))
if not report['pass']: raise SystemExit(1)
