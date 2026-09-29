#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,shutil,difflib
ROOT=Path(__file__).resolve().parents[4];BASE=ROOT/'selfhost/build/phase16/parser-semantic-source-05';OUT=ROOT/'selfhost/build/phase16/parser-literal-source-01';OUT.mkdir();shutil.copytree(BASE/'project',OUT/'project')
p=OUT/'project/src/front/elaborate.bend';s=p.read_text();a='u => k_with_span(f_literal(nm(t)), kb(t), ke(t))';assert s.count(a)==1;s=s.replace(a,'u => f_literal_at(t)');a='f_choose(KTerm, Char.is_eq(f_head(s), \'"\'), u => kt("Ctr", "SNil", 0, 1, Nil{}), u => f_string_decoded(f_decode_char(s)))';assert s.count(a)==1;s=s.replace(a,'f_string_at(s, atom("Absent"))');s+='''
@unsafe
def f_literal_at(+origin: KTerm) -> KTerm:
  f_choose(KTerm, Char.is_eq(f_head(nm(origin)), '"'),
    u => k_with_span(f_string_at(f_tail(nm(origin)), origin), kb(origin), ke(origin)),
    u => f_literal_value(origin, f_literal(nm(origin))))

@unsafe
def f_literal_value(+origin: KTerm, +value: KTerm) -> KTerm:
  f_choose(KTerm, f_eq(tg(value), "Error") && f_ascii_digit(f_head(nm(origin))) && U32.is_gt(kb(origin), 0),
    u => f_numeric_error(origin, nm(origin), 0, value), u => k_with_span(value, kb(origin), ke(origin)))

@unsafe
def f_numeric_error(+origin: KTerm, +rest: String, +offset: U32, +legacy: KTerm) -> KTerm:
  f_choose(KTerm, f_ascii_digit(f_head(rest)), u => f_numeric_error(origin, f_tail(rest), U32.add(offset, 1), legacy),
    u => f_choose(KTerm, String.is_empty(rest),
      u => fpe_expected_at(origin, nm(legacy), "a u32 literal up to 4294967295 (got " ++ nm(origin) ++ ")", "'" ++ nm(origin) ++ "'"),
      u => f_choose(KTerm, (Char.is_eq(f_head(rest), '.') && f_ascii_digit(f_head(f_tail(rest)))) || Char.is_eq(f_head(rest), 'n'),
        u => k_with_span(legacy, kb(origin), ke(origin)),
        u => fpe_expected_at(k_with_span(origin, U32.add(kb(origin), offset), U32.add(kb(origin), offset)), nm(legacy), "a numeric literal (NUMBER is U32, NUMBER n is Nat)", "'" ++ SCon{f_head(rest), ""} ++ "'"))))

@unsafe
def f_string_at(+s: String, +origin: KTerm) -> KTerm:
  f_choose(KTerm, Char.is_eq(f_head(s), '"'), u => kt("Ctr", "SNil", 0, 1, Nil{}), u => f_string_decoded_at(f_decode_char(s), origin))
''';p.write_text(s)
p=OUT/'project/src/front/unicode.bend';s=p.read_text();a='''def f_string_decoded(d):
  match d:
    case FDecoded{code, rest, +err}:
      f_choose(KTerm, String.is_empty(err), u => kt("Ctr", "SCon", 0, 1, [kt("Ctr", "Chr", 0, 1, [f_u32(code)]), f_string(rest)]), u => kt("Error", err, 0, 0, Nil{}))''';assert s.count(a)==1;s=s.replace(a,'''def f_string_decoded(d):
  f_string_decoded_at(d, atom("Absent"))''');s+='''
@unsafe
def f_string_decoded_at(+d: FDecoded, +origin: KTerm) -> KTerm:
  match d:
    case FDecoded{code, rest, err}:
      f_choose(KTerm, String.is_empty(err), u => kt("Ctr", "SCon", 0, 1, [kt("Ctr", "Chr", 0, 1, [f_u32(code)]), f_string_at(rest, origin)]),
        u => f_choose(KTerm, U32.is_gt(kb(origin), 0), u => f_escape_seek(origin, f_tail(nm(origin)), err), u => kt("Error", err, 0, 0, Nil{})))

@unsafe
def f_escape_seek(+origin: KTerm, +rest: String, +legacy: String) -> KTerm:
  f_choose(KTerm, String.is_empty(rest) || Char.is_eq(f_head(rest), '"'), u => kt("Error", legacy, 0, 0, Nil{}),
    u => f_escape_decoded(origin, rest, legacy, f_decode_char(rest)))

@unsafe
def f_escape_decoded(+origin: KTerm, +rest: String, +legacy: String, +decoded: FDecoded) -> KTerm:
  match decoded:
    case FDecoded{code, tail, error}:
      f_choose(KTerm, String.is_empty(error), u => f_escape_seek(origin, tail, legacy),
        u => fpe_expected_at(k_with_span(origin, U32.add(U32.sub(ke(origin), dg_width(rest)), 2), U32.add(U32.sub(ke(origin), dg_width(rest)), 2)), legacy, "an escape (\\\\n \\\\t \\\\r \\\\0 \\\\\\\\ \\\\\\' \\\\\\\" \\\\u{1F600})", "'" ++ SCon{f_head(f_tail(f_tail(rest))), ""} ++ "'"))
''';p.write_text(s)
config=json.loads((BASE/'workflow.json').read_text());config['project']=str(OUT/'project');(OUT/'workflow.json').write_text(json.dumps(config,indent=2)+'\n');shutil.copy2(__file__,OUT/Path(__file__).name)
changes=[]
for f in ['elaborate.bend','unicode.bend']:
 a=BASE/'project/src/front'/f;b=OUT/'project/src/front'/f;x=a.read_text();y=b.read_text();(OUT/(f+'.patch')).write_text(''.join(difflib.unified_diff(x.splitlines(True),y.splitlines(True),fromfile='parent/'+f,tofile='candidate/'+f)));changes.append({'file':'src/front/'+f,'beforeSha256':hashlib.sha256(a.read_bytes()).hexdigest(),'afterSha256':hashlib.sha256(b.read_bytes()).hexdigest()})
ids=['parse/expected_float_literal.bend','parse/hex_no_digits.bend','parse/word_overflow_literal.bend','parse/invalid_string_escape.bend'];(OUT/'selection.json').write_text(json.dumps({'cases':[{'id':x,'lanes':['parse','check']} for x in ids]},indent=2)+'\n');(OUT/'manifest.json').write_text(json.dumps({'complete':True,'parent':str(BASE),'plan':'experiments/phase16/P16-parser-literal-errors.md','changes':changes,'ids':ids},indent=2)+'\n');print(OUT)
