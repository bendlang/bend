#!/usr/bin/env python3
"""Collect concrete final-image owner receipts; never substitute old results."""
import hashlib,json,sys
from pathlib import Path
plan_file,config_file,output=[Path(x).resolve() for x in sys.argv[1:]]
assert not output.exists()
def identity(file):
 file=Path(file).resolve();return dict(file=str(file),sha256=hashlib.sha256(file.read_bytes()).hexdigest(),bytes=file.stat().st_size)
plan=json.loads(plan_file.read_text());config=json.loads(config_file.read_text())
assert config['attempt']['sha256']==plan['attempt']['sha256'] and config['api']['sha256']==plan['api']['sha256']
assert sorted(config['cases'])==sorted(plan['ownerGates'])
report=dict(kind='phase35-final-owner-controls',complete=False,pass_=False,attempt=config['attempt'],api=config['api'],
 inputs=[identity(__file__),identity(plan_file),identity(config_file)],cases=[])
report['pass']=report.pop('pass_')
try:
 for name in plan['ownerGates']:
  rows=[]
  for file in config['cases'][name]:
   data=json.loads(Path(file).read_text());assert data['complete'] and data['pass'] and not data.get('error'),file
   rows.append(identity(file))
  report['cases'].append(dict(name=name,returncode=0,reports=rows))
 report['complete']=report['pass']=True
finally:output.write_text(json.dumps(report,indent=2)+'\n')
print(json.dumps(dict(complete=True,groups=len(report['cases']))))
