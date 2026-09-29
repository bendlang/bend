"""Reuse the streamed profile reader for bounded range-cost caller attribution."""
from pathlib import Path
from array import array
import importlib.util
import json
import sys

helper=Path(__file__).resolve().parents[1]/'phase9/profile-callers.py'
spec=importlib.util.spec_from_file_location('phase9_callers',helper)
module=importlib.util.module_from_spec(spec);spec.loader.exec_module(module)
controls=module.self_test()
module.TARGETS={'$norm_join$','$driver_holes$','$sp_needed$','$sp_neededs$'}
original_skip=module.skip
module.skip=lambda frame:'target-recursion' if frame[0] in module.TARGETS else original_skip(frame)
source,destination=map(Path,sys.argv[1:])
destination.mkdir()
nf,parents,frames,metadata,count=module.read_profile(source)
result=module.analyze(nf,parents,frames,metadata)
assert result['nodes']==count
result.update({'kind':'phase16-range-cost-physical-callers','complete':True,
 'scope':'Exclusive samples of named targets, skipping their recursion and runtime/anonymous frames. Physical stacks may omit trampoline tail callers. Neither call counts nor measured allocation costs.',
 'inputs':[module.identity(source),module.identity(helper),module.identity(Path(__file__))],
 'controls':controls,'targetsRequested':sorted(module.TARGETS)})
(destination/'report.json').write_text(json.dumps(result,indent=2)+'\n')
(destination/'consumed-tool.py').write_bytes(Path(__file__).read_bytes())
for row in result['callers'][:20]:
 print(json.dumps({key:row[key] for key in ['target','caller','samples','selfUs','percentOfProfile']}))
