#!/usr/bin/env python3
from pathlib import Path
import hashlib,json,shutil
ROOT=Path(__file__).resolve().parents[4];BASE=ROOT/'selfhost/build/phase16/parser-semantic-source-03';OUT=ROOT/'selfhost/build/phase16/parser-semantic-source-04';OUT.mkdir();shutil.copytree(BASE/'project',OUT/'project')
p=OUT/'project/src/front/parser.bend';s=p.read_text();a='u => "Error:\\n- message  : " ++ nm(kid(error, 0)) ++ "\\nLocation:" ++ dg_snippet(DSpan{source, U32.sub(kb(error), start), U32.sub(ke(error), start)}),';b=a[:-2]+' ++ f_choose(String, f_eq(tg(kid(error, 1)), "ParseNote"), u => "\\nNote: " ++ nm(kid(error, 1)), u => ""),';assert s.count(a)==1;s=s.replace(a,b);s+='''
@unsafe
def fpe_message_note_at(+term: KTerm, +legacy: String, +message: String, +note: String) -> KTerm:
  kt_span("Error", legacy, 0, 0, [kt("ParseMessage", message, 0, 0, Nil{}), kt("ParseNote", note, 0, 0, Nil{})], kb(term), ke(term))
''';p.write_text(s)
p=OUT/'project/src/front/families.bend';s=p.read_text();a='fpe_message_at(t, message, message)';b='fpe_message_note_at(t, message, message, "we broke this after launch, sorry. Until 2.0.16 a bare operator meant Nat.\\nThat was a bug: operators demand annotation. Wrap the expression and it\'ll work again.")';assert s.count(a)==1;p.write_text(s.replace(a,b))
config=json.loads((BASE/'workflow.json').read_text());config['project']=str(OUT/'project');(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n');shutil.copy2(__file__,OUT/Path(__file__).name);(OUT/'manifest.json').write_text(json.dumps({'complete':True,'parent':str(BASE),'correction':'Explicit ParseNote payload for generic parser message errors; pinned operator note after exact source snippet.','changes':[{'file':str(p.relative_to(OUT/'project')),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in [OUT/'project/src/front/parser.bend',OUT/'project/src/front/families.bend']]},indent=2)+'\n');print(OUT)
