# Additive source provenance consumes the actual loader trace and final
# freshened core, preserving origins through qualification and substitutions.
# Only Ref/ADT/Ctr nodes retaining an actual lexer position receive an origin;
# generated nodes and variable occurrences whose positions were erased do not.
type FProvenance is Data:
  FProvenance{+result: FResult, +origins: List<&2,DOrigin>}

type FPSource is Data:
  FPSource{+source: String, +tokens: List<&2,FToken>}

law f_load_origins:
  for +main: String
  for +sources: List<&2,FSource>
  FProvenance
law fp_def:
  for +d: KDef
  for +source: FPSource
  List<&2,DOrigin>
law fp_ctors:
  for +ctors: List<&2,KDef>
  for +definition: String
  for +source: FPSource
  for +index: U32
  List<&2,DOrigin>
law fp_term:
  for +t: KTerm
  for +definition: String
  for +source: FPSource
  for +route: List<&2,U32>
  List<&2,DOrigin>
law fp_children:
  for +terms: List<&2,KTerm>
  for +definition: String
  for +source: FPSource
  for +route: List<&2,U32>
  for +index: U32
  List<&2,DOrigin>
law fp_origin:
  for +t: KTerm
  for +definition: String
  for +source: FPSource
  for +route: List<&2,U32>
  List<&2,DOrigin>
law fp_find_token:
  for +tokens: List<&2,FToken>
  for +line: U32
  for +column: U32
  List<&2,FToken>
law fp_at_token:
  for +t: KTerm
  for +definition: String
  for +text: String
  for +tokens: List<&2,FToken>
  for +route: List<&2,U32>
  List<&2,DOrigin>
law fp_token_origin:
  for +t: KTerm
  for +definition: String
  for +text: String
  for +token: FToken
  for +route: List<&2,U32>
  List<&2,DOrigin>
law fp_utf16:
  for +text: String
  U32
law fp_offset:
  for +text: String
  for +line: U32
  for +column: U32
  for +targetLine: U32
  for +targetColumn: U32
  for +offset: U32
  U32

@unsafe
def f_load_origins(main, sources):
  fp_loaded_origins(f_load_graph_trace(main, sources), True{}, "")
@unsafe
def fp_def(d, source):
  List.append(&2,DOrigin, fp_term(dt(d), dn(d), source, [0]), List.append(&2,DOrigin, fp_term(dv(d), dn(d), source, [1]), fp_ctors(dc(d), dn(d), source, 0)))
@unsafe
def fp_ctors(ctors, definition, source, index):
  match ctors:
    case Nil{}:
      Nil{}
    case Con{ctor, rest}:
      List.append(&2,DOrigin, fp_term(dt(ctor), definition, source, [2,index,0]), fp_ctors(rest, definition, source, U32.add(index, 1)))
@unsafe
def fp_term(t, definition, source, route):
  List.append(&2,DOrigin, fp_origin(t, definition, source, route), fp_children(ks(t), definition, source, route, 0))
@unsafe
def fp_children(terms, definition, source, route, index):
  match terms:
    case Nil{}:
      Nil{}
    case Con{term, rest}:
      List.append(&2,DOrigin, fp_term(term, definition, source, List.append(&2,U32, route, [index])), fp_children(rest, definition, source, route, U32.add(index, 1)))
@unsafe
def fp_origin(t, definition, source, route):
  match source:
    case FPSource{text, tokens}:
      f_choose(List<&2,DOrigin>, (String.eq(tg(t), "Ref") || String.eq(tg(t), "ADT") || String.eq(tg(t), "Ctr")) && U32.is_ge(ix(t), 65536), u => fp_at_token(t, definition, text, fp_find_token(tokens, U32.div(ix(t), 65536), U32.mod(ix(t), 65536)), route), u => Nil{})
@unsafe
def fp_find_token(tokens, line, column):
  match tokens:
    case Nil{}:
      Nil{}
    case Con{token, rest}:
      f_choose(List<&2,FToken>, U32.is_eq(f_line(tokens), line) && U32.is_eq(f_col(tokens), column), u => tokens, u => fp_find_token(rest, line, column))
@unsafe
def fp_at_token(t, definition, text, tokens, route):
  match tokens:
    case Nil{}:
      Nil{}
    case Con{token, rest}:
      fp_token_origin(t, definition, text, token, route)
@unsafe
def fp_token_origin(t, definition, text, token, route):
  match token:
    case FToken{word, line, column, kind}:
      +begin = fp_offset(text, 1, 0, line, column, 0)
      [DOrigin{definition, t, text, begin, U32.add(begin, fp_utf16(word)), route}]
@unsafe
def fp_utf16(text):
  f_choose(U32, String.is_empty(text), u => 0, u => U32.add(f_choose(U32, U32.is_gt(Char.to_u32(f_head(text)), 65535), u => 2, u => 1), fp_utf16(f_tail(text))))
@unsafe
def fp_offset(text, line, column, targetLine, targetColumn, offset):
  f_choose(U32, String.is_empty(text) || (U32.is_eq(line, targetLine) && U32.is_eq(column, targetColumn)), u => offset, u => fp_offset(f_tail(text), f_choose(U32, Char.is_eq(f_head(text), '\n'), u => U32.add(line, 1), u => line), f_choose(U32, Char.is_eq(f_head(text), '\n'), u => 0, u => U32.add(column, 1)), targetLine, targetColumn, U32.add(offset, f_choose(U32, U32.is_gt(Char.to_u32(f_head(text)), 65535), u => 2, u => 1))))

# Rejection-only lookup limits expensive source mapping to the definition named
# by the structured checker event. No diagnostic text is parsed or interpreted.
law f_load_origins_for:
  for +main: String
  for +sources: List<&2,FSource>
  for +definition: String
  FProvenance
@unsafe
def f_load_origins_for(main, sources, definition):
  f_loaded_origins_for(f_load_graph_trace(main, sources), definition)

# One trace owns module order and declaration counts for both origin APIs.
# Filtered lookup lexes only matching modules; source is never reparsed here.
law f_loaded_origins_for:
  for +trace: FLoadTrace
  for +definition: String
  FProvenance
law fp_loaded_origins:
  for +trace: FLoadTrace
  for +all: Bool
  for +definition: String
  FProvenance
law fp_loaded_modules:
  for +done: List<&2,KTerm>
  for +book: List<&2,KDef>
  for +sources: List<&2,FSource>
  for +all: Bool
  for +definition: String
  List<&2,DOrigin>
law fp_loaded_take:
  for +book: List<&2,KDef>
  for +count: U32
  List<&2,KDef>
law fp_loaded_drop:
  for +book: List<&2,KDef>
  for +count: U32
  List<&2,KDef>
law fp_loaded_has:
  for +book: List<&2,KDef>
  for +definition: String
  Bool
law fp_loaded_module:
  for +book: List<&2,KDef>
  for +source: FSource
  for +all: Bool
  for +definition: String
  List<&2,DOrigin>
law fp_loaded_defs:
  for +book: List<&2,KDef>
  for +source: FPSource
  for +all: Bool
  for +definition: String
  List<&2,DOrigin>

@unsafe
def f_loaded_origins_for(trace, definition):
  fp_loaded_origins(trace, False{}, definition)
@unsafe
def fp_loaded_origins(trace, all, definition):
  match trace:
    case FLoadTrace{+result, done, sources}:
      fp_loaded_result(result, done, sources, all, definition)
@unsafe
def fp_loaded_modules(done, book, sources, all, definition):
  match done:
    case Nil{}: Nil{}
    case Con{+entry, rest}:
      List.append(&2, DOrigin, fp_loaded_module(fp_loaded_take(book, ix(entry)), f_graph_source(nm(entry), sources), all, definition), fp_loaded_modules(rest, fp_loaded_drop(book, ix(entry)), sources, all, definition))
@unsafe
def fp_loaded_take(book, count):
  match book:
    case Nil{}: Nil{}
    case Con{head, tail}: f_choose(List<&2,KDef>, U32.is_eq(count, 0), u => Nil{}, u => Con{head, fp_loaded_take(tail, U32.sub(count, 1))})
@unsafe
def fp_loaded_drop(book, count):
  match book:
    case Nil{}: Nil{}
    case Con{head, tail}: f_choose(List<&2,KDef>, U32.is_eq(count, 0), u => book, u => fp_loaded_drop(tail, U32.sub(count, 1)))
@unsafe
def fp_loaded_has(book, definition):
  match book:
    case Nil{}: False{}
    case Con{head, tail}: f_choose(Bool, String.eq(dn(head), definition), u => True{}, u => fp_loaded_has(tail, definition))
@unsafe
def fp_loaded_module(book, source, all, definition):
  f_choose(List<&2,DOrigin>, f_choose(Bool, all, u => True{}, u => fp_loaded_has(book, definition)), u => fp_loaded_defs(book, FPSource{f_source_text(source), f_lex(f_source_text(source), 1, 0, 0, Nil{})}, all, definition), u => Nil{})
@unsafe
def fp_loaded_defs(book, source, all, definition):
  match book:
    case Nil{}: Nil{}
    case Con{head, tail}:
      List.append(&2, DOrigin, f_choose(List<&2,DOrigin>, all || String.eq(dn(head), definition), u => fp_def(head, source), u => Nil{}), fp_loaded_defs(tail, source, all, definition))

law fp_loaded_result:
  for +result: FResult
  for +done: List<&2,KTerm>
  for +sources: List<&2,FSource>
  for +all: Bool
  for +definition: String
  FProvenance
@unsafe
def fp_loaded_result(result, done, sources, all, definition):
  match result:
    case FResult{book, error, imports}:
      FProvenance{result, f_choose(List<&2,DOrigin>, String.is_empty(error), u => fp_loaded_modules(List.reverse(&2,KTerm,done), book, sources, all, definition), u => Nil{})}
