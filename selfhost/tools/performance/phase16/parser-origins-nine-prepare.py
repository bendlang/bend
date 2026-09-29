#!/usr/bin/env python3
from pathlib import Path
import difflib,hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[4];BASE=ROOT/'selfhost/build/phase16/parser-span-source-08/project';OUT=ROOT/'selfhost/build/phase16/parser-span-source-09';OUT.mkdir();shutil.copytree(BASE,OUT/'project');P=OUT/'project/src'
def change(file,a,b):
 p=P/file;s=p.read_text();assert s.count(a)==1,(file,a,s.count(a));p.write_text(s.replace(a,b))
change('front/parser.bend','case FParsed{n, ts}:\n      FParsed{f_choose(KTerm, U32.is_eq(begin, 0) || f_eq(tg(n), "Error") || (U32.is_gt(kb(n), 0) && Bool.not(force)), u => n, u => f_located_term(n, begin, f_choose(U32, spaced, u => f_begin(f_space(ts)), u => f_previous_end(ts)), created)), ts}', 'case FParsed{n, ts}:\n      +end = f_choose(U32, spaced, u => f_begin(f_space(ts)), u => f_previous_end(ts))\n      FParsed{f_choose(KTerm, U32.is_eq(begin, 0) || U32.is_lt(end, begin) || f_eq(tg(n), "Error") || (U32.is_gt(kb(n), 0) && Bool.not(force)), u => n, u => f_located_term(n, begin, end, created)), ts}')
change('front/parser.bend','case FParsed{n, ts}: FParsed{k_with_span(n, end, end), ts}','case FParsed{n, ts}: FParsed{f_choose(KTerm, f_eq(tg(n), "Error"), u => n, u => k_with_span(n, end, end)), ts}')
change('front/sugar.bend','], begin, f_begin(f_space(ts))), ts}','], f_choose(U32, U32.is_eq(f_begin(f_space(ts)), 0), u => 0, u => begin), f_begin(f_space(ts))), ts}')
changes=[]
for p in sorted(P.rglob('*.bend')):
 before=(BASE/'src'/p.relative_to(P)).read_text();after=p.read_text()
 if before!=after:
  rel='src/'+p.relative_to(P).as_posix();changes.append({'file':rel,'sha256':hashlib.sha256(p.read_bytes()).hexdigest(),'lineDelta':len(after.splitlines())-len(before.splitlines())});(OUT/(p.name+'.patch')).write_text(''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile='parent/'+rel,tofile='candidate/'+rel)))
config=json.loads((BASE.parent/'workflow.json').read_text());config['project']=str(OUT/'project');(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n');shutil.copy2(__file__,OUT/Path(__file__).name);(OUT/'manifest.json').write_text(json.dumps({'complete':True,'parent':str(BASE),'changes':changes,'reason':'Root full gate found seven rejected partial ASTs with a wrapper start but no consumed endpoint; absence is preserved rather than manufacturing a source range.','preparerSha256':hashlib.sha256(Path(__file__).read_bytes()).hexdigest()},indent=2)+'\n');print(OUT)
