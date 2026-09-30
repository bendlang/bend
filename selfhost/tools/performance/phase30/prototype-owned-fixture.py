#!/usr/bin/env python3
"""Freeze the canonical source plus a scalar-input, internally allocated row probe."""
from pathlib import Path
import hashlib,json,shutil,sys
HERE=Path(__file__).resolve().parent;ROOT=HERE.parents[3]
out=Path(sys.argv[1]).resolve();out.mkdir(parents=True,exist_ok=False)
source=HERE.parent/'phase28/corpus/editdist.bend'
design=ROOT/'design/phase30/closed-owned-row-first-ladder.md'
def ident(p):
 raw=p.read_bytes();return {'file':str(p),'sha256':hashlib.sha256(raw).hexdigest(),'bytes':len(raw)}
suffix='''
# Phase30 diagnostic: scalar inputs; all four array handles originate here.
def row.probe(+n: U32, +seed: U32) -> Dp:
  +count = U32.to_nat(n)
  a = gen(count, 0, seed, [0 : U32*128n])
  b = gen(count, 0, U32.mul(seed, 340573321), [0 : U32*128n])
  prev = init(U32.to_nat(U32.inc(n)), 0, [0 : U32*128n])
  row(count, 0, U32.and(seed, 3), Dp{a, b, prev, [0 : U32*128n]})
'''
target=out/'row.bend';target.write_text(source.read_text()+suffix)
shutil.copyfile(Path(__file__),out/'consumed-fixture.py');shutil.copyfile(design,out/'design.md')
report={'kind':'phase30-closed-owned-row-source','complete':True,'inputs':[ident(p)for p in [Path(__file__),source,design]],'suffix':suffix,'output':ident(target)}
(out/'source.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps(report))
