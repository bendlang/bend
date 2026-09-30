#!/usr/bin/env python3
"""Derive and preserve a prospectively selected longer-warmup comparison."""
from pathlib import Path
import hashlib,json,subprocess,sys
HERE=Path(__file__).resolve().parent
configfile,out=map(lambda p:Path(p).resolve(),sys.argv[1:]);config=json.loads(configfile.read_text())
assert [c['id'] for c in config['cases']]==['mandelbrot','tree-bitonic','test-morning-program','test-map-set-ops']
assert not out.exists();out.parent.mkdir(parents=True,exist_ok=True)
runner=HERE/'execute.mjs';launcher=HERE/'measure.py'
original=runner.read_text();launch=launcher.read_text()
assert original.count('report.warmup<3||performance.now()-warm<1000')==1
derived=original.replace('report.warmup<3||performance.now()-warm<1000','report.warmup<100||performance.now()-warm<3000')
runner_copy=out.with_suffix('.execute.mjs');launcher_copy=out.with_suffix('.measure.py')
assert not runner_copy.exists() and not launcher_copy.exists()
runner_copy.write_text(derived)
assert launch.count('HERE=Path(__file__).resolve().parent')==1
launch=launch.replace('HERE=Path(__file__).resolve().parent','HERE=Path('+repr(str(HERE))+')')
launch=launch.replace("HERE/'execute.mjs'",'Path('+repr(str(runner_copy))+')')
launch=launch.replace('then>=3 calls AND1000ms warmup','then>=100 calls AND3000ms warmup')
launcher_copy.write_text(launch)
identity=lambda p:{'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
receipt={'complete':True,'originalRunner':identity(runner),'originalLauncher':identity(launcher),'runner':identity(runner_copy),'launcher':identity(launcher_copy),
 'scope':'Only warmup floors and recorded runner/path bindings change; all original comparison operations remain.'}
out.with_suffix('.derivation.json').write_text(json.dumps(receipt,indent=2)+'\n')
result=subprocess.run([sys.executable,str(launcher_copy),str(configfile),str(out)])
assert identity(runner)==receipt['originalRunner'] and identity(launcher)==receipt['originalLauncher']
raise SystemExit(result.returncode)
