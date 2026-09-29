from pathlib import Path
import hashlib,json,shutil
root=Path(__file__).resolve().parents[4];out=root/'selfhost/build/phase16/bare-family-fixtures-01';out.mkdir()
box='import Base\ntype Box<-A: Type> is Type:\n  Box{value: A}\n'
token='import Base\ntype Token<q> is Kind(q):\n  Token{}\n'
cases=[
 ('ordinary-bare',False,box+'def bad(x: Box) -> Unit: Unit{}\ndef main() -> U32: 0\n'),
 ('ordinary-explicit',True,box+'def good(x: Box<U32>) -> Unit: Unit{}\ndef main() -> U32: 0\n'),
 ('quantity-bare',False,token+'def main() -> Token: Token{}\n'),
 ('quantity-explicit',True,token+'def main() -> Token<&1>: Token{}\n'),
 ('quantity-marked',True,token+'def main() -> +Token: Token{}\n'),
 ('lexical-shadow',True,box+'def identity(-Box: Type, x: Box) -> Box: x\ndef main() -> U32: identity(U32, 0)\n'),
 ('zero-arity',True,'import Base\ntype Token is Data:\n  Token{}\ndef main() -> Token: Token{}\n'),
]
selection=[{'id':'check/family_head_bare.bend','lanes':['check']}];inputs=[]
for name,accept,source in cases:
 p=out/(name+'.bend');p.write_text(source);inputs.append({'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
 row={'id':'bare-family/'+name,'file':str(p),'lanes':['check'],'accept':accept}
 if not accept:row['rejectPhase']='check'
 selection.append(row)
(out/'selection.json').write_text(json.dumps(selection,indent=2)+'\n');(out/'manifest.json').write_text(json.dumps({'inputs':inputs,'toolSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()},indent=2)+'\n');shutil.copy2(__file__,out/'consumed-tool.py');print(out)
