#!/usr/bin/env python3
"""Disposable four-way ablation. These rewrites are NOT compiler results.

A rewrites saturated U32 calls inside sel/asr8/mit only. B retains the exact
public Zero/Succ matcher and residual descriptor, replacing only the Succ arm
callback with a private saturated loop. The counter remains BigInt.
"""
from pathlib import Path
import hashlib,json,re,sys
HERE=Path(__file__).resolve().parent
source=Path(sys.argv[1]).resolve();out=Path(sys.argv[2]).resolve()
out.mkdir(parents=True,exist_ok=False)
text=source.read_text()
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'bytes':p.stat().st_size}
targets=['sel','asr8','mit']
ops={'add':lambda a,b:f'((({a})+({b}))>>>0)',
     'sub':lambda a,b:f'((({a})-({b}))>>>0)',
     'mul':lambda a,b:f'(Math.imul(({a}),({b}))>>>0)',
     'or':lambda a,b:f'((({a})|({b}))>>>0)',
     'is_gt':lambda a,b:f'(({a})>({b}))',
     'is_zero':lambda a:f'(({a})===0)',
     'shrn':lambda a,b:f'((p29a,p29n)=>p29n>=32n?0:p29a>>>Number(p29n))({a},{b})'}
counts={}
def arguments(text,start):
    # start immediately follows opening '['. This emitted subset has no strings
    # in primitive arguments except those inside balanced runtime calls.
    stack=[];current=[];parts=[];quote=None;escaped=False
    for i in range(start,len(text)):
        ch=text[i]
        if quote:
            current.append(ch)
            if escaped:escaped=False
            elif ch=='\\':escaped=True
            elif ch==quote:quote=None
            continue
        if ch in '\"\'`':quote=ch;current.append(ch);continue
        if ch in '([{':stack.append(ch);current.append(ch);continue
        if ch in ')]}':
            if not stack:
                assert ch==']'
                if ''.join(current).strip():parts.append(''.join(current))
                assert text[i+1]==')'
                return parts,i+2
            assert '([{'.index(stack.pop())==')]}'.index(ch)
            current.append(ch);continue
        if ch==',' and not stack:
            if ''.join(current).strip():parts.append(''.join(current))
            current=[]
        else:current.append(ch)
    raise AssertionError('unterminated emitted argument list')
def arithmetic(code):
    pattern=re.compile(r'(?:call|jump)\(get\(G,"U32\.([a-z_]+)"\),\[')
    cursor=0;result=''
    while True:
        m=pattern.search(code,cursor)
        if not m:return result+code[cursor:]
        args,end=arguments(code,m.end())
        if m.group(1) not in ops:
            result+=code[cursor:end];cursor=end;continue
        args=[arithmetic(a) for a in args]
        counts[m.group(1)]=counts.get(m.group(1),0)+1
        result+=code[cursor:m.start()]+ops[m.group(1)](*args);cursor=end
def modify_arithmetic(text):
    lines=text.splitlines(keepends=True)
    return ''.join(arithmetic(line) if any(line.startswith('G['+json.dumps(t)+']=') for t in targets) or line.startswith('function p29_mit(') else line for line in lines)

worker='''function p29_mit(n,cr,ci,zr,zi,esc,it){for(;;){if(n===0n)return it;const p=n-1n;const r2=call(get(G,"asr8"),[call(get(G,"U32.mul"),[zr,zr])]);const i2=call(get(G,"asr8"),[call(get(G,"U32.mul"),[zi,zi])]);const e2=call(get(G,"U32.or"),[esc,call(get(G,"b2u"),[call(get(G,"U32.is_gt"),[call(get(G,"U32.add"),[r2,i2]),1024])])]);const nzr=call(get(G,"U32.add"),[call(get(G,"U32.sub"),[r2,i2]),cr]);const nzi=call(get(G,"U32.add"),[call(get(G,"asr8"),[call(get(G,"U32.mul"),[2,call(get(G,"U32.mul"),[zr,zi])])]),ci]);const sr=call(get(G,"sel"),[e2,nzr,zr]);const si=call(get(G,"sel"),[e2,nzi,zi]);const nextIt=call(get(G,"U32.add"),[it,call(get(G,"b2u"),[call(get(G,"U32.is_zero"),[e2])])]);n=p;zr=sr;zi=si;esc=e2;it=nextIt;}}
'''
def loop(text):
    lines=text.splitlines(keepends=True);hit=0
    for i,line in enumerate(lines):
        if not line.startswith('G["mit"]='):continue
        hit+=1
        # Copy the existing public matcher exactly through the Succ callback's
        # parameter binders. Only that callback's return expression changes.
        marker='matcher1p("Succ",1,7,()=>(0,function(a){'
        assert line.count(marker)==1
        left,rest=line.split(marker)
        binders=re.match(r'(?:const x[0-9]+=a\[[0-9]+\];){7}return ',rest)
        assert binders
        names=re.findall(r'const (x[0-9]+)=a\[[0-9]+\];',binders.group())
        assert line.endswith('}))))\n') or line.endswith('}))));\n')
        callback='return p29_mit('+','.join([names[0]+'+1n',*names[1:]])+');'
        lines[i]=worker+left+marker+binders.group()[:-len('return ')]+callback+'}))));\n'
    assert hit==1
    return ''.join(lines)
report={'kind':'phase29-disposable-generated-JS-ablation','complete':False,'source':ident(source),'tool':ident(Path(__file__)),'scope':'Hand-transformed mechanism experiment, NOT compiler-generated improvement.','operations':sorted(ops),'arithmeticScope':targets,'workerScope':'Only mit recursive body; public matched first argument and residual fn descriptor retained; BigInt counter unchanged.','variants':{}}
for name,body in [('unchanged',text),('arithmetic',modify_arithmetic(text)),('worker',loop(text)),('combined',modify_arithmetic(loop(text)))]:
    p=out/(name+'.mjs');p.write_text(body);report['variants'][name]=ident(p)
report['transformationCountsAcrossArithmeticAndCombined']=counts
assert ident(source)==report['source'];report['complete']=True
(out/'derivation.json').write_text(json.dumps(report,indent=2)+'\n')
