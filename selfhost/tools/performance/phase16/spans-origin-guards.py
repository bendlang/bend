#!/usr/bin/env python3
from pathlib import Path
P=Path(__file__).resolve().parents[4]/'selfhost/build/phase16/spans-origin-source-01/project'
p=P/'src/diagnostic/frontend.bend';s=p.read_text()
s=s.replace('case FLoadTrace{result, done, sources}: FProvenance{result, fp_origins(sources)}','''case FLoadTrace{result, done, sources}:
      match result:
        case FResult{book, error, imports}:
          f_choose(FProvenance, Bool.not(String.is_empty(error)) || fp_defs_ranges(book, sources), u => FProvenance{result, fp_origins(sources)}, u => FProvenance{FResult{Nil{}, "invalid term source interval", Nil{}}, Nil{}})''')
s+='''
# Low-level loader inputs remain trusted ASTs. This source-aware boundary checks
# all ranges before it exposes origins; valid synthesized nodes are exactly 0/0.
law fp_range_owned:
  for +begin: U32
  for +end: U32
  for +sources: List<&2,FSource>
  Bool
law fp_terms_ranges:
  for +terms: List<&2,KTerm>
  for +sources: List<&2,FSource>
  Bool
law fp_defs_ranges:
  for +defs: List<&2,KDef>
  for +sources: List<&2,FSource>
  Bool

@unsafe
def fp_range_owned(begin, end, sources):
  match sources:
    case Nil{}: False{}
    case Con{head, rest}:
      f_choose(Bool, U32.is_gt(f_source_begin(head), 0) && U32.is_ge(begin, f_source_begin(head)) && U32.is_ge(end, begin) && U32.is_lt(end, f_source_end(head)), u => True{}, u => fp_range_owned(begin, end, rest))

@unsafe
def fp_terms_ranges(terms, sources):
  match terms:
    case Nil{}: True{}
    case Con{head, rest}:
      f_choose(Bool, f_choose(Bool, U32.is_eq(kb(head), 0), u => U32.is_eq(ke(head), 0), u => fp_range_owned(kb(head), ke(head), sources)), u => fp_terms_ranges(norm_join(ks(head), rest), sources), u => False{})

@unsafe
def fp_defs_ranges(defs, sources):
  match defs:
    case Nil{}: True{}
    case Con{head, rest}:
      f_choose(Bool, fp_terms_ranges([dt(head), dv(head)], sources), u => fp_defs_ranges(norm_defs_join(dc(head), rest), sources), u => False{})
'''
p.write_text(s)
print(P)
