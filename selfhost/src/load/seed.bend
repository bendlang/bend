# Reuse a driver-validated Base core book only for the exact source it cached.
# Both canonical path and complete source text must match. The seed is inserted
# lazily at Base's normal dependency position, never merely because it was
# supplied. All other graph checks and final global alpha-renaming still run.
# The driver binds seedBook to the checked Base bytes and compiler API hash.
type FSeed is Data:
  FSeed{+path: String, +book: List<&2, KDef>, +root: String}

law f_seed_matches:
  for +source: FSource
  for +path: String
  for +text: String
  Bool

law fs_load:
  for +path: String
  for +ns: String
  for +sources: List<&2, FSource>
  for +g: FGraph
  for +stack: List<&2, String>
  for +seed: FSeed
  FGraph

law fs_source:
  for +s: FSource
  for +ns: String
  for +sources: List<&2, FSource>
  for +g: FGraph
  for +stack: List<&2, String>
  for +seed: FSeed
  FGraph

law fs_cached:
  for +s: FSource
  for +ns: String
  for +sources: List<&2, FSource>
  for +g: FGraph
  for +stack: List<&2, String>
  for +entry: KTerm
  for +seed: FSeed
  FGraph

law fs_inject:
  for +g: FGraph
  for +seed: FSeed
  FGraph

law fs_parsed:
  for +s: FSource
  for +ns: String
  for +sources: List<&2, FSource>
  for +g: FGraph
  for +stack: List<&2, String>
  for +r: FHeader
  for +seed: FSeed
  FGraph

law fs_imports:
  for +s: FSource
  for +ns: String
  for +header: FHeader
  for +imports: List<&2, KTerm>
  for +sources: List<&2, FSource>
  for +g: FGraph
  for +stack: List<&2, String>
  for +seed: FSeed
  FGraph

@unsafe
def f_load_graph_seed(
  +main: String,
  +sources: List<&2, FSource>,
  +seedPath: String,
  +seedText: String,
  +seedBook: List<&2, KDef>,
) -> FResult:
  f_choose(FResult, f_seed_matches(f_source("Base", sources), seedPath, seedText), u => f_graph_result_at(fs_load(main, "", sources, FGraph{Nil{}, "", Nil{}}, Nil{}, FSeed{seedPath, seedBook, f_path_dir(f_source_path(f_graph_source(main, sources)))}), sources), u => f_load_graph(main, sources))

@unsafe
def f_seed_matches(source, path, text):
  Bool.not(String.is_empty(path)) && f_eq(f_source_name(source), "Base") && f_eq(f_source_path(source), path) && f_seed_text_equal(f_source_text(source), text)

@unsafe
def fs_path(
  +seed: FSeed,
) -> String:
  match seed:
    case FSeed{path, book, root}:
      path

@unsafe
def fs_book(
  +seed: FSeed,
) -> List<&2, KDef>:
  match seed:
    case FSeed{path, book, root}:
      book

@unsafe
def fs_load(path, ns, sources, g, stack, seed):
  fs_source(f_graph_source(path, sources), ns, sources, g, stack, seed)

@unsafe
def fs_source(s, ns, sources, g, stack, seed):
  match g:
    case FGraph{book, +err, +done}:
      f_choose(FGraph, Bool.not(String.is_empty(err)), u => FGraph{book, err, done}, u => f_choose(FGraph, String.is_empty(f_source_path(s)), u => FGraph{book, "module source was not supplied", done}, u => f_choose(FGraph, has_name(stack, f_source_path(s)), u => FGraph{book, "cyclic import through " ++ f_source_path(s), done}, u => fs_cached(s, ns, sources, FGraph{book, err, done}, stack, f_env(f_source_path(s), done), seed))))

@unsafe
def fs_cached(s, ns, sources, g, stack, entry, seed):
  f_choose(FGraph, f_eq(tg(entry), "Absent"), u => f_choose(FGraph, String.is_empty(ns) && f_eq(f_source_name(s), "Base") && f_eq(f_source_path(s), fs_path(seed)), u => fs_inject(g, seed), u => fs_parsed(s, ns, sources, g, Con{f_source_path(s), stack}, f_source_header(s), seed)), u => g)

@unsafe
def fs_inject(g, seed):
  match g:
    case FGraph{book, err, done}:
      FGraph{norm_defs_join(book, fs_book(seed)), err, Con{kt("Loaded", fs_path(seed), f_graph_count_defs(fs_book(seed), 0), 0, [ref("")]), done}}

@unsafe
def fs_parsed(s, ns, sources, g, stack, r, seed):
  fs_imports(s, ns, r, f_header_imports(r), sources, g, stack, seed)

@unsafe
def fs_imports(s, ns, header, imports, sources, g, stack, seed):
  match imports:
    case Nil{}:
      f_completion_graph(f_complete_source(s, ns, header, sources, g, fs_root(seed)))
    case Con{im, rest}:
      fs_imports(s, ns, header, rest, sources, fs_load(f_import_pathname(im, s, sources), f_import_namespace_at(im, s, sources, fs_root(seed)), sources, g, stack, seed), stack, seed)


# Base is larger than the call-stack limit of the library's recursive compare.
# This equality scan is tail-recursive and compares the entire source exactly.
law f_seed_text_equal:
  for +a: String
  for +b: String
  Bool

@unsafe
def f_seed_text_equal(a, b):
  match a b:
    case SNil{} SNil{}:
      True{}
    case SCon{x, xs} SCon{y, ys}:
      f_choose(Bool, Char.is_eq(x, y), u => f_seed_text_equal(xs, ys), u => False{})
    case _ _:
      False{}

@unsafe
def f_load_graph_seed_trace(
  +main: String,
  +sources: List<&2,FSource>,
  +seedPath: String,
  +seedText: String,
  +seedBook: List<&2,KDef>,
) -> FLoadTrace:
  f_choose(FLoadTrace, f_seed_matches(f_source("Base", sources), seedPath, seedText), u => f_graph_trace(fs_load(main, "", sources, FGraph{Nil{}, "", Nil{}}, Nil{}, FSeed{seedPath, seedBook, f_path_dir(f_source_path(f_graph_source(main, sources)))}), sources), u => f_load_graph_trace(main, sources))

@unsafe
def fs_root(+seed: FSeed) -> String:
  match seed:
    case FSeed{path, book, root}: root
