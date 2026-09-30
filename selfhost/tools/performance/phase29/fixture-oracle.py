#!/usr/bin/env python3
"""Independent integer oracle: Python arithmetic and explicit modulo 2**32.

The result schema/point order reproduce fixture-points.json exactly. It does not
read generated JavaScript, runtime helpers, or compiler outputs.
"""
import json
def oracle(n,cr,ci,zr,zi,esc,it):
    mask=2**32-1
    def u(x):return x&mask
    def asr(v):return u((v if v<2**31 else v-2**32)>>8)
    for _ in range(n):
        r2=asr(u(zr*zr));i2=asr(u(zi*zi));e2=esc|int(u(r2+i2)>1024)
        nzr=u(r2-i2+cr);nzi=u(asr(u(2*u(zr*zi)))+ci)
        zr=nzr if e2==0 else zr;zi=nzi if e2==0 else zi
        esc=e2;it=u(it+int(e2==0))
    return it
points=[]
for n in [0,1,2,7,31,128]:
    for cr,ci,zr,zi,esc,it in [(0,0,0,0,0,0),(2**32-512,2**32-384,0,0,0,0),(1,255,256,0,0,0),(2**32-1,1,65535,65536,0,2**32-1),(2**31,2**31-1,2**32-1,2**32-1,0,0),(1,1,1,1,1,19),(0,0,0,0,0,2**32-1),(0,0,0,0,2**32-1,2**32-1)]:
        args=[n,cr,ci,zr,zi,esc,it]
        points.append({'exportName':'point','args':args,'expected':oracle(*args)})
state=12345
for i in range(64):
    vals=[]
    for _ in range(7):
        state=(1664525*state+1013904223)&(2**32-1);vals.append(state)
    vals[0]%=65;vals[5]=0 if i%3 else vals[5]
    points.append({'exportName':'point','args':vals,'expected':oracle(*vals)})
bench=[]
for n,seed in [(7,0),(128,524800),(128,262400),(128,123456),(128,0),(128,1048575),(31,524600),(0,524800)]:
    cr=((seed&1023)-512)&(2**32-1);ci=(((seed>>10)&1023)-512)&(2**32-1)
    bench.append({'exportName':'bench','args':[n,seed],'expected':oracle(n,cr,ci,0,0,0,0)})
print(json.dumps({'kind':'phase29-independent-python-U32-fixed-point-oracles','oracle':'Python arbitrary-precision integers with explicit modulo2^32; arithmetic shift uses signed two-complement conversion; frozen before any candidate execution.','pointCount':len(points)+len(bench),'points':points+bench,'suggestedTimingPoint':bench[1]},indent=2))
