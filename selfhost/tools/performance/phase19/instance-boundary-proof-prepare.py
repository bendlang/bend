"""Frozen proof-safety witness, separate from already consumed boundary inputs."""
from pathlib import Path
import hashlib,json,sys
root=Path(__file__).resolve().parents[4];out=Path(sys.argv[1]).resolve();out.mkdir()
header='type Nat is Data:\n  Zero{}\n  Succ{pred: Nat}\n'
for name,number in [('original',0),('changed',1)]:
 (out/(name+'.bend')).write_text(header+f'def proof() -> {{0n == {number}n : Nat}}:\n  {{==}}\n')
def identity(p):return {'file':str(p.resolve()),'bytes':p.stat().st_size,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
plan={'kind':'phase19-literal-prefix-proof-safety','parentAttempt':str(root/'selfhost/build/phase18/instance-world-build-06'),'upstream':str(root/'selfhost/.bootstrap/upstream-phase8'),'pin':'b2111cf43244e65f76ddc278ee695e669f720cbf','original':str(out/'original.bend'),'changed':str(out/'changed.bend'),'expected':{'originalAccepted':True,'changedFullAccepted':False,'changedCachedAccepted':False,'changedExactPrefix':False},'scope':'Self-contained Nat supplies the literal equality proof without Base. Only the second compact Nat payload changes; source ranges are deliberately not identity. Parent acceptance of changedCached is a retained bug witness, not an allowed expected outcome.','inputs':[identity(Path(__file__)),identity(out/'original.bend'),identity(out/'changed.bend')]}
(out/'plan.json').write_text(json.dumps(plan,indent=2)+'\n');print(json.dumps({'plan':str(out/'plan.json')}))
