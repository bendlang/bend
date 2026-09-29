from pathlib import Path
import json, shutil

root=Path(__file__).resolve().parents[4]
out=root/'selfhost/build/phase16/module-names-controls-01'
out.mkdir()
fixtures=out/'fixtures'
fixtures.mkdir()
upstream=root/'selfhost/.bootstrap/upstream-phase8/tests/import/goal-alias'
shutil.copy2(upstream/'mod.bend',fixtures/'mod.bend')
cases=[{'id':f'import/{name}.bend','lanes':['check']} for name in ['goal_alias','goal_own']]

def case(name,body,positive=False):
    file=fixtures/(name+'.bend')
    file.write_text(body)
    row={'id':'module-names/'+name,'file':str(file),'lanes':['check'],'accept':positive}
    if not positive:row['rejectPhase']='check'
    cases.append(row)

for order in [('A','B'),('B','A')]:
    first,last=order
    case('alias-order-'+first,'import Base\n'+''.join(f'import ./mod.bend as {alias}\n' for alias in order)+f'def wrong(x: Nat) -> {{{last}.quad(x) == x : Nat}}:\n  {{==}}\n')
case('alias-local-shadow','import Base\nimport ./mod.bend as M\ndef wrong(M.double: Nat) -> {M.quad(M.double) == M.double : Nat}:\n  {==}\n')
(fixtures/'own.bend').write_text('import Base\nlaw own: Nat -> Nat\ndef wrong(x: Nat) -> {own(x) == x : Nat}:\n  {==}\n')
case('own-namespace','import Base\nimport ./own.bend as O\n')
(fixtures/'types.bend').write_text('type Box is Data:\n  Item{}\n')
case('aliased-datatype','import Base\nimport ./types.bend as T\ndef wrong() -> T.Box: True{}\n')
case('aliased-constructor','import Base\nimport ./types.bend as T\ndef wrong() -> Bool: T.Item{}\n')
case('builtin-sugar','import Base\ndef wrong() -> Bool: [1n, 2n]\n')
case('valid-import','import Base\nimport ./mod.bend as M\ndef main() -> Nat: M.quad(2n)\n',True)
(out/'selection.json').write_text(json.dumps({'cases':cases},indent=2)+'\n')
shutil.copy2(__file__,out/'consumed-tool.py')
print(out)
