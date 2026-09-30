#!/usr/bin/env python3
"""Preserve and derive the Phase28 whole-process runner for three variants."""
from pathlib import Path
import hashlib,json,subprocess,sys
HERE=Path(__file__).resolve().parent
config,out=map(lambda p:Path(p).resolve(),sys.argv[1:])
derivation=out.with_name(out.name+'-derivation')
derivation.mkdir(parents=True,exist_ok=False)
original=HERE.parent/'phase28/measure-application.py'
source=original.read_text()
replacements=[
 ("assert set(config['variants'])=={'upstream','selfhost'}", "assert set(config['variants'])=={'upstream','selfhost','candidate'}"),
 ("order=['upstream','selfhost'] if index%2==0 else ['selfhost','upstream']", "sides=list(config['variants']); order=sides[index%3:]+sides[:index%3]"),
 ("for side in ['upstream','selfhost']:", "for side in config['variants']:"),
 ("phase28-application-process-timing", "phase29-application-process-timing"),
 ("for both variants", "for all three variants"),
]
for old,new in replacements:
    assert source.count(old)==1,old
    source=source.replace(old,new)
(derivation/'original.py').write_bytes(original.read_bytes())
derived=derivation/'runner.py';derived.write_text(source)
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
receipt={'inputs':[ident(Path(__file__)),ident(original),ident(config)],'derived':ident(derived),
 'changes':replacements,'scope':'Only side enumeration/order and labels change. Resource limits, five samples, full-output checks and process timing are unchanged.'}
(derivation/'receipt.json').write_text(json.dumps(receipt,indent=2)+'\n')
result=subprocess.run([sys.executable,str(derived),str(config),str(out)])
for item in [*receipt['inputs'],receipt['derived']]:assert ident(Path(item['file']))==item
raise SystemExit(result.returncode)
