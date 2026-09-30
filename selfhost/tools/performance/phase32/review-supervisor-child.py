#!/usr/bin/env python3
"""Tiny bounded negative-control child. Never starts compiler processes."""
import argparse,json,os,resource,time
from pathlib import Path
p=argparse.ArgumentParser();p.add_argument('mode',choices=['memory','deadline']);p.add_argument('receipt');a=p.parse_args()
# Independent hard address-space ceiling bounds this test even if RSS watching fails.
resource.setrlimit(resource.RLIMIT_AS,(256*1024**2,256*1024**2))
raw=Path('/proc/self/stat').read_text();fields=raw[raw.rfind(')')+2:].split()
receipt={'pid':os.getpid(),'startTicks':fields[19],'mode':a.mode,'addressSpaceLimitBytes':256*1024**2}
Path(a.receipt).write_text(json.dumps(receipt,indent=2)+'\n')
if a.mode=='memory':
 data=bytearray(160*1024**2)
 for i in range(0,len(data),4096):data[i]=1
 receipt['allocatedBytes']=len(data)
 Path(a.receipt+'.allocated').write_text(json.dumps(receipt,indent=2)+'\n')
time.sleep(10)
# Normal completion is a control failure: the supervisor should kill us first.
raise SystemExit(42)
