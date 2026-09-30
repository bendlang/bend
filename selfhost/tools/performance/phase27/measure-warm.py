#!/usr/bin/env python3
"""Replay the maintained three-output harness with a prospective warmup policy."""
from pathlib import Path
import hashlib,json,subprocess,sys

HERE=Path(__file__).resolve().parent
source=HERE.parent/'phase26/measure.py'
configfile,out=[Path(p).resolve() for p in sys.argv[1:]]
original=source.read_text()
assert original.count('math.ceil(150*result[\'repetitions\']/result[\'executionMs\'])')==1
assert original.count("TOOLS=Path(__file__).resolve().parent")==1
assert original.count('side-specific 150ms calibration')==1
config=json.loads(configfile.read_text())
assert [c['id'] for c in config['cases']]==['term-substitution','compiler-membership','boolean-worker']
for c in config['cases']:
    assert c['point']['warmup']==200 and c['point']['warmupMs']==500
assert not out.exists();out.parent.mkdir(parents=True,exist_ok=True)
# This launcher preserves every original timing/checking/ordering operation;
# only calibration target and TOOL path binding differ in the recorded copy.
script=out.with_suffix('.launcher.py')
assert not script.exists()
transformed=original.replace("TOOLS=Path(__file__).resolve().parent",'TOOLS=Path('+repr(str(source.parent))+')').replace("math.ceil(150*result['repetitions']/result['executionMs'])","math.ceil(500*result['repetitions']/result['executionMs'])").replace('>=100ms/eight calls warmup, side-specific 150ms calibration','>=500ms/200 calls warmup, side-specific 500ms calibration').replace("'kind':'phase26-three-output-runtime'","'kind':'phase27-longer-warm-runtime'")
script.write_text(transformed)
receipt=out.with_suffix('.launcher.json')
receipt.write_text(json.dumps({'source':str(source),'sourceSha256':hashlib.sha256(source.read_bytes()).hexdigest(),'launcher':str(script),'launcherSha256':hashlib.sha256(script.read_bytes()).hexdigest(),'scope':'Unchanged comparison machinery with recorded500ms target and explicit200call/500ms point warmup; source outputs remain untouched.'},indent=2)+'\n')
result=subprocess.run([sys.executable,str(script),str(configfile),str(out)])
assert hashlib.sha256(source.read_bytes()).hexdigest()==json.loads(receipt.read_text())['sourceSha256']
raise SystemExit(result.returncode)
