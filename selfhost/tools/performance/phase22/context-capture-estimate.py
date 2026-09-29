#!/usr/bin/env python3
"""Read-only exact framing compression estimate; writes no archive or extraction."""
from pathlib import Path
import gzip, hashlib, json, os, stat, sys, tarfile
ROOT=Path(__file__).resolve().parents[4]
plan_path=Path(sys.argv[1]).resolve();out=Path(sys.argv[2]).resolve()
assert not out.exists(); initial_plan=plan_path.read_bytes(); plan=json.loads(initial_plan)
files={};deps=[]
def add(p,topic):
    rel=p.relative_to(ROOT).as_posix()
    assert not any(rel==x or rel.startswith(x+'/') for x in plan['excludedTrees'])
    assert '.git' not in p.relative_to(ROOT).parts
    if rel in files: assert files[rel]==topic
    else:files[rel]=topic
def tree(p,topic):
    assert p.exists() or p.is_symlink(),str(p)
    if p.is_file() or p.is_symlink():add(p,topic);return
    for directory,dirs,names in os.walk(p,followlinks=False):
        for name in list(dirs):
            q=Path(directory)/name
            if q.is_symlink():add(q,topic);dirs.remove(name)
        for name in names:add(Path(directory)/name,topic)
for topic,names in plan['extraTrees'].items():
    for name in names:tree(ROOT/name,topic)
for topic,names in plan['extraFiles'].items():
    for name in names:tree(ROOT/name,topic)
for name in list(files):
    document=ROOT/name
    if not (document.name.endswith('selection.json') or document.name.endswith('cases.json')):continue
    pending=[json.loads(document.read_text())]
    while pending:
        value=pending.pop()
        if isinstance(value,list):pending.extend(value)
        elif isinstance(value,dict):
            pending.extend(value.values());target=value.get('file')
            if not isinstance(target,str) or not target.endswith('.bend'):continue
            target=Path(target)
            if not target.is_absolute():target=document.parent/target
            target=Path(os.path.abspath(target));assert target.is_relative_to(ROOT)
            relative=target.relative_to(ROOT).as_posix()
            if relative.startswith('selfhost/.bootstrap/') or relative in files:continue
            assert target.is_file(),relative
            assert target.parent not in [ROOT,ROOT/'selfhost',ROOT/plan['phaseRoot']]
            deps.append({'selection':name,'fixture':relative,'tree':target.parent.relative_to(ROOT).as_posix()})
            tree(target.parent,'final')
rows=[]
for name,topic in sorted(files.items()):
    p=ROOT/name;s=p.lstat();assert stat.S_ISREG(s.st_mode) or stat.S_ISLNK(s.st_mode)
    row={'path':name,'topic':topic,'mode':stat.S_IMODE(s.st_mode),'type':'symlink' if stat.S_ISLNK(s.st_mode) else 'file','bytes':len(os.fsencode(os.readlink(p))) if stat.S_ISLNK(s.st_mode) else s.st_size}
    if row['type']=='symlink':row['target']=os.readlink(p)
    row['_identity']=(s.st_dev,s.st_ino,s.st_size,s.st_mode,s.st_mtime_ns,s.st_ctime_ns);rows.append(row)
class Counter:
    def __init__(self):self.bytes=0
    def write(self,data):self.bytes+=len(data);return len(data)
    def flush(self):pass
    def tell(self):return self.bytes
parts=[]
for topic in plan['topics']:
    batches=[[]];size=0
    for row in [r for r in rows if r['topic']==topic]:
        assert row['bytes']<plan['maxPartPayloadBytes'],row['path']
        cost=((row['bytes']+511)//512+4)*512
        if batches[-1] and size+cost>plan['maxPartPayloadBytes']:batches.append([]);size=0
        batches[-1].append(row);size+=cost
    for number,batch in enumerate(batches,1):
        if not batch:continue
        counter=Counter()
        with gzip.GzipFile(filename='',mode='wb',fileobj=counter,compresslevel=6,mtime=0) as zipped,tarfile.open(fileobj=zipped,mode='w') as tar:
            for row in batch:
                info=tarfile.TarInfo(row['path']);info.uid=info.gid=info.mtime=0;info.mode=row['mode']
                if row['type']=='symlink':info.type=tarfile.SYMTYPE;info.linkname=row['target'];tar.addfile(info)
                else:
                    info.size=row['bytes']
                    with (ROOT/row['path']).open('rb') as f:tar.addfile(info,f)
        parts.append({'name':topic+'-'+str(number).zfill(2)+'.tar.gz','members':len(batch),'regularPayloadBytes':sum(r['bytes'] for r in batch if r['type']=='file'),'compressedBytes':counter.bytes})
        print(json.dumps(parts[-1]),flush=True)
for row in rows:
    s=(ROOT/row['path']).lstat();assert row.pop('_identity')==(s.st_dev,s.st_ino,s.st_size,s.st_mode,s.st_mtime_ns,s.st_ctime_ns),row['path']
assert plan_path.read_bytes()==initial_plan
pfx=plan['finalSource']+'/'
summary={'kind':'phase22-readonly-capture-framing-estimate','complete':True,'captureRun':False,'plan':str(plan_path),'planSha256':hashlib.sha256(initial_plan).hexdigest(),'toolSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest(),'memberCount':len(rows),'logicalBytes':sum(r['bytes'] for r in rows),'maxMember':max(rows,key=lambda r:r['bytes']),'compressedBytes':sum(p['compressedBytes'] for p in parts),'parts':parts,'sourceMembership':{'files':sum(r['path'].startswith(pfx) for r in rows),'bytes':sum(r['bytes'] for r in rows if r['path'].startswith(pfx))},'fixtureDependencies':deps,'members':rows,'scope':'Exact gzip byte count for these proposed files with collector framing; no archives written and no release hashes frozen. Final inventory/patch/manifest and new freeze/review metadata add overhead.'}
with out.open('x') as f:json.dump(summary,f,indent=2);f.write('\n')
print(json.dumps({k:summary[k] for k in ['complete','memberCount','logicalBytes','compressedBytes','maxMember','sourceMembership']}),flush=True)
