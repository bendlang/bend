#!/usr/bin/env python3
"""Owned location model/lookup overlay on the immutable migrated source."""
from pathlib import Path
ROOT=Path(__file__).resolve().parents[4]
P=ROOT/'selfhost/build/phase16/spans-origin-source-01/project'
p=P/'src/load/modules.bend';s=p.read_text()
s=s.replace('  FParsedSource{+name: String, +path: String, +text: String, +parsed: FResult}', '  FParsedSource{+name: String, +path: String, +text: String, +parsed: FResult}\n  FLocatedSource{+source: FSource, begin: U32, end: U32}')
for what in ['name','text','path']:
    needle=f'    case FParsedSource{{name, path, text, parsed}}:\n      {what}'
    assert s.count(needle)==1
    s=s.replace(needle,needle+f'\n    case FLocatedSource{{source, begin, end}}:\n      f_source_{what}(source)')
s=s.replace('    case FParsedSource{name, path, text, parsed}:\n      parsed', '    case FParsedSource{name, path, text, parsed}:\n      parsed\n    case FLocatedSource{source, begin, end}:\n      f_parse_source_located(source, begin)')
s+='''
# Location ownership is separate from raw/parsed source delivery.
@unsafe
def f_source_located(+source: FSource, +begin: U32, +end: U32) -> FSource:
  FLocatedSource{source, begin, end}

@unsafe
def f_source_begin(+source: FSource) -> U32:
  match source:
    case FSource{name, path, text}: 0
    case FParsedSource{name, path, text, parsed}: 0
    case FLocatedSource{source, begin, end}: begin

@unsafe
def f_source_end(+source: FSource) -> U32:
  match source:
    case FSource{name, path, text}: 0
    case FParsedSource{name, path, text, parsed}: 0
    case FLocatedSource{source, begin, end}: end

@unsafe
def f_parse_source_located(+source: FSource, +begin: U32) -> FResult:
  match source:
    case FSource{name, path, text}: f_parse_indexed(begin, text)
    case FParsedSource{name, path, text, parsed}: parsed
    case FLocatedSource{source, innerBegin, innerEnd}:
      FResult{Nil{}, "nested source location wrapper", Nil{}}
'''
p.write_text(s)
p=P/'src/diagnostic/model.bend';s=p.read_text();s=s.replace('  DOrigin{+definition: String, +term: KTerm, +source: String, begin: U32, end: U32, +path: List<&2, U32>}', '  DSourceOrigin{+source: String, begin: U32, end: U32}');p.write_text(s)
p=P/'src/diagnostic/produce.bend';s=p.read_text();a=s.index('@unsafe\ndef dg_span_same(');b=s.index('@unsafe\ndef dg_has_span(',a);s=s[:a]+s[b:];a=s.index('law dg_span_fields:');b=s.index('law dg_origin_found:',a);s=s[:a]+s[b:]
a=s.index('@unsafe\ndef dg_origin_scan(');b=s.index('@unsafe\ndef dg_origin_trail(',a)
s=s[:a]+'''# Positive ranges resolve by their owning immutable source interval, not by
# definition names or structural term equality. EOF is the reserved last point.
@unsafe
def dg_origin_span(+origins: List<&2,DOrigin>, +begin: U32, +end: U32) -> DSpan:
  match origins:
    case Nil{}: DNoSpan{}
    case Con{DSourceOrigin{source, first, limit}, rest}:
      kc(DSpan, U32.is_gt(first, 0) && U32.is_gt(limit, first) && U32.is_ge(begin, first) && U32.is_ge(end, begin) && U32.is_lt(end, limit),
        u => DSpan{source, U32.sub(begin, first), U32.sub(end, first)},
        u => dg_origin_span(rest, begin, end))

'''+s[b:]
s=s.replace('dg_origin_scan(origins, name, h, DNoSpan{})','dg_origin_span(origins, kb(h), ke(h))')
p.write_text(s)

(P/'src/diagnostic/frontend.bend').write_text('''# Parser-owned ranges are resolved through immutable source intervals. An
# unlocated legacy trace is explicitly replayed; no term/text matching remains.
type FProvenance is Data:
  FProvenance{+result: FResult, +origins: List<&2,DOrigin>}

type FPSourceSet is Data:
  FPSourceSet{+sources: List<&2,FSource>, +error: String}

law fp_units:
  for +text: String
  for +count: U32
  U32
law fp_source_validate:
  for +source: FSource
  for +seen: List<&2,FSource>
  String
law fp_source_pairs:
  for +source: FSource
  for +seen: List<&2,FSource>
  String
law fp_source_inputs:
  for +sources: List<&2,FSource>
  for +seen: List<&2,FSource>
  String
law fp_source_limit:
  for +sources: List<&2,FSource>
  for +limit: U32
  U32
law fp_source_prior:
  for +path: String
  for +sources: List<&2,FSource>
  FSource
law fp_index_sources:
  for +sources: List<&2,FSource>
  for +seen: List<&2,FSource>
  for +next: U32
  FPSourceSet
law fp_index_one:
  for +source: FSource
  for +rest: List<&2,FSource>
  for +seen: List<&2,FSource>
  for +next: U32
  for +prior: FSource
  FPSourceSet
law fp_index_fresh:
  for +source: FSource
  for +rest: List<&2,FSource>
  for +seen: List<&2,FSource>
  for +next: U32
  for +size: U32
  FPSourceSet
law fp_origins:
  for +sources: List<&2,FSource>
  List<&2,DOrigin>
law fp_located:
  for +sources: List<&2,FSource>
  Bool
law fp_load_indexed:
  for +main: String
  for +inputs: FPSourceSet
  FProvenance
law fp_trace_ready:
  for +trace: FLoadTrace
  FProvenance

@unsafe
def fp_units(text, count):
  match text:
    case SNil{}: count
    case SCon{head, rest}: fp_units(rest, U32.add(count, dg_units(head)))

@unsafe
def fp_source_validate(source, seen):
  match source:
    case FSource{name, path, text}: fp_source_pairs(source, seen)
    case FParsedSource{name, path, text, parsed}: fp_source_pairs(source, seen)
    case FLocatedSource{inner, begin, end}:
      match inner:
        case FLocatedSource{nested, a, b}: "nested source location wrapper"
        case FSource{name, path, text}:
          f_choose(String, U32.is_gt(begin, 0) && U32.is_gt(end, begin) && U32.is_eq(U32.sub(end, begin), U32.add(fp_units(text, 0), 1)), u => fp_source_pairs(source, seen), u => "invalid source interval")
        case FParsedSource{name, path, text, parsed}:
          f_choose(String, U32.is_gt(begin, 0) && U32.is_gt(end, begin) && U32.is_eq(U32.sub(end, begin), U32.add(fp_units(text, 0), 1)), u => fp_source_pairs(source, seen), u => "invalid source interval")

@unsafe
def fp_source_pairs(source, seen):
  match seen:
    case Nil{}: ""
    case Con{old, rest}:
      f_choose(String, String.eq(f_source_path(source), f_source_path(old)),
        u => f_choose(String, String.eq(f_source_text(source), f_source_text(old)) && U32.is_eq(f_source_begin(source), f_source_begin(old)) && U32.is_eq(f_source_end(source), f_source_end(old)), u => fp_source_pairs(source, rest), u => "source alias ownership changed"),
        u => f_choose(String, U32.is_gt(f_source_begin(source), 0) && U32.is_gt(f_source_begin(old), 0) && U32.is_lt(f_source_begin(source), f_source_end(old)) && U32.is_lt(f_source_begin(old), f_source_end(source)), u => "overlapping source intervals", u => fp_source_pairs(source, rest)))

@unsafe
def fp_source_inputs(sources, seen):
  match sources:
    case Nil{}: ""
    case Con{head, rest}:
      +error = fp_source_validate(head, seen)
      f_choose(String, String.is_empty(error), u => fp_source_inputs(rest, Con{head, seen}), u => error)

@unsafe
def fp_source_limit(sources, limit):
  match sources:
    case Nil{}: limit
    case Con{head, rest}: fp_source_limit(rest, norm_max(limit, f_source_end(head)))

@unsafe
def fp_source_prior(path, sources):
  match sources:
    case Nil{}: FSource{"", "", ""}
    case Con{head, rest}: f_choose(FSource, String.eq(path, f_source_path(head)), u => head, u => fp_source_prior(path, rest))

@unsafe
def fp_index_sources(sources, seen, next):
  match sources:
    case Nil{}: FPSourceSet{List.reverse(&2,FSource,seen), ""}
    case Con{head, rest}:
      f_choose(FPSourceSet, U32.is_gt(f_source_begin(head), 0), u => fp_index_sources(rest, Con{head, seen}, next), u => fp_index_one(head, rest, seen, next, fp_source_prior(f_source_path(head), seen)))

@unsafe
def fp_index_one(source, rest, seen, next, prior):
  f_choose(FPSourceSet, U32.is_gt(f_source_begin(prior), 0),
    u => fp_index_sources(rest, Con{FLocatedSource{FSource{f_source_name(source), f_source_path(source), f_source_text(source)}, f_source_begin(prior), f_source_end(prior)}, seen}, next),
    u => fp_index_fresh(source, rest, seen, next, fp_units(f_source_text(source), 0)))

@unsafe
def fp_index_fresh(source, rest, seen, next, size):
  f_choose(FPSourceSet, U32.is_lt(size, U32.sub(4294967295, next)),
    u => fp_index_sources(rest, Con{FLocatedSource{FSource{f_source_name(source), f_source_path(source), f_source_text(source)}, next, U32.add(next, U32.add(size, 1))}, seen}, U32.add(next, U32.add(size, 1))),
    u => FPSourceSet{Nil{}, "source interval overflow"})

@unsafe
def fp_origins(sources):
  match sources:
    case Nil{}: Nil{}
    case Con{head, rest}: Con{DSourceOrigin{f_source_text(head), f_source_begin(head), f_source_end(head)}, fp_origins(rest)}

@unsafe
def fp_located(sources):
  match sources:
    case Nil{}: True{}
    case Con{head, rest}: U32.is_gt(f_source_begin(head), 0) && fp_located(rest)

@unsafe
def f_load_origins(+main: String, +sources: List<&2,FSource>) -> FProvenance:
  f_load_origins_for(main, sources, "")

@unsafe
def f_load_origins_for(+main: String, +sources: List<&2,FSource>, +definition: String) -> FProvenance:
  +error = fp_source_inputs(sources, Nil{})
  f_choose(FProvenance, String.is_empty(error), u => fp_load_indexed(main, fp_index_sources(sources, Nil{}, fp_source_limit(sources, 1))), u => FProvenance{FResult{Nil{}, error, Nil{}}, Nil{}})

@unsafe
def fp_load_indexed(main, inputs):
  match inputs:
    case FPSourceSet{sources, error}:
      f_choose(FProvenance, String.is_empty(error), u => fp_trace_ready(f_load_graph_trace(main, sources)), u => FProvenance{FResult{Nil{}, error, Nil{}}, Nil{}})

@unsafe
def fp_trace_ready(trace):
  match trace:
    case FLoadTrace{result, done, sources}: FProvenance{result, fp_origins(sources)}

# Rechecking result.book is required after the explicitly unlocated replay path.
@unsafe
def f_loaded_origins_for(+trace: FLoadTrace, +definition: String) -> FProvenance:
  match trace:
    case FLoadTrace{result, done, sources}:
      match result:
        case FResult{book, error, imports}:
          f_choose(FProvenance, Bool.not(String.is_empty(error)), u => FProvenance{result, Nil{}},
            u => f_choose(FProvenance, fp_located(sources),
              u => f_choose(FProvenance, String.is_empty(fp_source_inputs(sources, Nil{})), u => fp_trace_ready(trace), u => FProvenance{FResult{Nil{}, "invalid located trace source ownership", Nil{}}, Nil{}}),
              u => f_choose(FProvenance, List.is_empty(&2,KTerm,done), u => FProvenance{result, Nil{}}, u => f_load_origins_for(nm(terms_at(done, 0)), sources, definition))))
''')
print(P)
