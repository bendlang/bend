#!/usr/bin/env python3
from pathlib import Path
import shutil,json,hashlib,difflib
R=Path(__file__).resolve().parents[4];base=R/'selfhost/build/phase16/spans-integration-source-04/project';out=R/'selfhost/build/phase16/spans-allocation-source-01';out.mkdir();P=out/'project';shutil.copytree(base,P);p=P/'src/front/parser.bend';old=p.read_text();needle='  f_choose(KTerm, U32.is_eq(begin, 0) || U32.is_gt(kb(t), 0), u => t, u => k_with_span(k_with_children(t, f_spans_created(ks(t), begin, end)), begin, end))';assert old.count(needle)==1;s=old.replace(needle,'''  match t:
    case KTerm{tag, name, id, quant, kids, removed, oldBegin, oldEnd}:
      f_choose(KTerm, U32.is_eq(begin, 0) || U32.is_gt(oldBegin, 0), u => t,
        u => KTerm{tag, name, id, quant, f_spans_created(kids, begin, end), removed, begin, end})''');p.write_text(s);shutil.copy2(__file__,out/Path(__file__).name)
(out/'workflow.json').write_text(json.dumps({'project':str(P),'upstream':str(R/'selfhost/.bootstrap/upstream-phase8'),'cpu':'2','jobs':1,'profile':'equality','timeoutMs':30000},indent=2)+'\n');(out/'parser.patch').write_text(''.join(difflib.unified_diff(old.splitlines(True),s.splitlines(True),fromfile='a/src/front/parser.bend',tofile='b/src/front/parser.bend')))
(out/'manifest.json').write_text(json.dumps({'baseline':str(base),'project':str(P),'experiment':str(R/'experiments/phase16/P16-002D-source-span-allocation.md'),'changes':[{'relative':'src/front/parser.bend','before':hashlib.sha256(old.encode()).hexdigest(),'after':hashlib.sha256(s.encode()).hexdigest()}],'staticChange':{'recordAllocationsPerFilledNode':[2,1],'projectorCallsPerVisitedNode':[1,0],'additionalProjectorCallsPerFilledNode':[1,0],'addedDefinitions':0,'addedTypes':0,'addedPasses':0}},indent=2)+'\n');print(P)
