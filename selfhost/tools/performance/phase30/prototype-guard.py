#!/usr/bin/env python3
"""Add live-G replacement guards to immutable Phase30 call-only prototype."""
from pathlib import Path
import hashlib,json,re,shutil,sys
base=Path(sys.argv[1]).resolve();out=Path(sys.argv[2]).resolve();out.mkdir(parents=True,exist_ok=False)
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
def save(p,v):p.write_text(json.dumps(v,indent=2)+'\n')
report={'kind':'phase30-guarded-private-call-ablation','complete':False,'scope':'Private call ablation with descriptor identity guards preserving live G replacement. Does not guard in-place mutation of captured descriptor internals. Not a compiler version. No timing.','inputs':[ident(p) for p in [Path(__file__),base/'report.json',base/'rewrites.json',base/'private.mjs']],'variants':{}}
source=(base/'private.mjs').read_text();changes=[]
for change in json.loads((base/'rewrites.json').read_text()):
    old,new=change['from'],change['to']
    name=re.search(r'get\(G,"(cell(?:\.f[1-4])?)"\)',old).group(1)
    value='P_known_'+name.replace('.','_')
    get=f'get(G,"{name}")'
    if old.startswith('return '):
        assert old.endswith(';') and new.startswith('return ') and new.endswith(';')
        guarded='return ((f)=>f==='+value+'?'+new[7:-1]+':'+old[7:-1].replace(get,'f',1)+')('+get+');'
    else:guarded='((f)=>f==='+value+'?'+new+':'+old.replace(get,'f',1)+')('+get+')'
    assert source.count(new)==1,new;source=source.replace(new,guarded)
    source+='\nconst '+value+'=G['+json.dumps(name)+'];\n';changes.append({'from':new,'to':guarded})
for side in ['unchanged','private','upstream']:
    path=out/(side+'.mjs');shutil.copyfile(base/(side+'.mjs'),path);report['variants'][side]=ident(path)
p=out/'guarded.mjs';p.write_text(source);report['variants']['guarded']=ident(p)
shutil.copyfile(base/'points.json',out/'points.json');shutil.copyfile(base/'source.bend',out/'source.bend')
save(out/'guards.json',changes)
for protocol in ['screen','confirm']:
    config=json.loads((base/(protocol+'.json')).read_text());config['inputs']+=[ident(out/'guards.json'),ident(Path(__file__))]
    config['cases'][0]['modules']={k:v['file'] for k,v in report['variants'].items()};save(out/(protocol+'.json'),config)
report.update(complete=True,guards=ident(out/'guards.json'));save(out/'report.json',report);print(json.dumps(report))
