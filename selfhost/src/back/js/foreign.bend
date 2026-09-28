import Base

# Foreign source linkage, argument erasure and ABI descriptors.
@unsafe
def j_foreign_path(
  +paths: List<&2, KTerm>,
) -> String:
  match paths:
    case Nil{}:
      ""
    case Con{h, rest}:
      kc(String, String.ends_with(nm(h), ".js\"") || String.ends_with(nm(h), ".js"), u => nm(h), u => j_foreign_path(rest))

@unsafe
def j_foreign_name(
  +name: String,
) -> String:
  j_foreign_chars(String.to_lower(name))

law j_foreign_chars:
  for +name: String
  String

@unsafe
def j_foreign_chars(name):
  match name:
    case SNil{}:
      ""
    case SCon{h, rest}:
      kc(String, Char.is_eq(h, '.') || Char.is_eq(h, '/'), u => "_", u => Char.show(h)) ++ j_foreign_chars(rest)

@unsafe
def j_foreign_def(
  +book: List<&2, KDef>,
  +d: KDef,
) -> String:
  kc(String, j_builtin_effect(dn(d)), u => "if(!Object.hasOwn(G," ++ j_quote(dn(d)) ++ "))", u => "") ++ "G[" ++ j_quote(dn(d)) ++ "]=fn(" ++ U32.show(da(d)) ++ ",function(a){const v=scope(null);return {io:()=>foreignCall(" ++ j_quote(j_foreign_path(ks(dv(d)))) ++ "," ++ j_quote(dn(d)) ++ ",a,[" ++ j_foreign_args(book, dt(d), da(d)) ++ "]," ++ j_descriptor(book, j_io_result(book, j_foreign_return(book, dt(d), da(d))), 64) ++ ")};});\n"

law j_foreign_args:
  for +book: List<&2, KDef>
  for +ty: KTerm
  for +n: U32
  String

@unsafe
def j_foreign_args(book, ty, n):
  kc(String, U32.is_eq(n, 0), u => "", u => "[" ++ U32.show(qt(ty)) ++ "," ++ j_descriptor(book, kid(ty, 0), 64) ++ "]," ++ j_foreign_args(book, kid(ty, 1), U32.sub(n, 1)))

law j_foreign_return:
  for +book: List<&2, KDef>
  for +ty: KTerm
  for +n: U32
  KTerm

@unsafe
def j_foreign_return(book, ty, n):
  kc(KTerm, U32.is_eq(n, 0), u => wnf(book, ty), u => j_foreign_return(book, kid(ty, 1), U32.sub(n, 1)))

law j_io_result:
  for +book: List<&2, KDef>
  for +ty: KTerm
  KTerm

@unsafe
def j_io_result(book, ty):
  kid(wnf(book, kid(wnf(book, kid(ty, 1)), 0)), 0)

@unsafe
def j_modules(
  +book: List<&2, KDef>,
  +sources: List<&2, KTerm>,
) -> String:
  match sources:
    case Nil{}:
      ""
    case Con{source, rest}:
      "foreignModules[" ++ j_quote(nm(source)) ++ "]=(()=>{const registered=Object.create(null);const io_eff=(name,fn)=>{registered[name]=fn;};\n" ++ j_source_parts(ks(source)) ++ "\nreturn Object.assign({" ++ j_module_exports(book, nm(source)) ++ "},registered);})();\n" ++ j_modules(book, rest)

law j_module_exports:
  for +book: List<&2, KDef>
  for +path: String
  String

@unsafe
def j_module_exports(book, path):
  match book:
    case Nil{}:
      ""
    case Con{d, rest}:
      kc(String, String.eq(tg(dv(d)), "Foreign") && String.eq(j_foreign_path(ks(dv(d))), path), u => j_module_export(dn(d), j_foreign_name(kc(String, String.eq(nm(dv(d)), ""), u => dn(d), u => nm(dv(d))))), u => "") ++ j_module_exports(rest, path)

law j_module_export:
  for +name: String
  for +implementation: String
  String

@unsafe
def j_module_export(name, implementation):
  j_quote(name) ++ ":typeof " ++ implementation ++ "===\"function\"?" ++ implementation ++ ":undefined,"

@unsafe
def j_ctor_metadata(
  +defs: List<&2, KDef>,
) -> String:
  match defs:
    case Nil{}:
      ""
    case Con{d, rest}:
      j_ctor_keys(dc(d), da(d)) ++ j_ctor_metadata(rest)

law j_ctor_keys:
  for +ctors: List<&2, KDef>
  for +params: U32
  String

@unsafe
def j_ctor_keys(ctors, params):
  match ctors:
    case Nil{}:
      ""
    case Con{d, rest}:
      "constructorNative[" ++ j_quote(dn(d)) ++ "]=" ++ kc(String, db(d), u => "true", u => "false") ++ ";constructorOwn[" ++ j_quote(dn(d)) ++ "]=" ++ j_quote(kc(String, String.eq(nm(dv(d)), ""), u => dn(d), u => nm(dv(d)))) ++ ";constructors[" ++ j_quote(dn(d)) ++ "]=[" ++ j_field_keys(dt(d), params) ++ "];\n" ++ j_ctor_keys(rest, params)

law j_field_keys:
  for +ty: KTerm
  for +skip: U32
  String

@unsafe
def j_field_keys(ty, skip):
  kc(String, String.eq(tg(ty), "All"), u => kc(String, U32.is_eq(skip, 0), u => j_quote(nm(ty)) ++ "," ++ j_field_keys(kid(ty, 1), 0), u => j_field_keys(kid(ty, 1), U32.sub(skip, 1))), u => "")

# Called after reachability: the host reads exactly these foreign source bytes.
@unsafe
def j_foreign_paths(
  +book: List<&2, KDef>,
) -> List<&2, String>:
  match book:
    case Nil{}:
      Nil{}
    case Con{d, rest}:
      kc(List<&2, String>, String.eq(tg(j_strip(dv(d))), "Foreign") && Bool.not(j_builtin_effect(dn(d))), u => Con{j_foreign_path(ks(j_strip(dv(d)))), j_foreign_paths(rest)}, u => j_foreign_paths(rest))

@unsafe
def j_foreign_error(
  +book: List<&2, KDef>,
) -> String:
  match book:
    case Nil{}:
      ""
    case Con{d, rest}:
      kc(String, String.eq(tg(j_strip(dv(d))), "Foreign") && Bool.not(j_builtin_effect(dn(d))) && String.eq(j_foreign_path(ks(j_strip(dv(d)))), ""), u => "a foreign def without a .js import: " ++ dn(d), u => j_foreign_error(rest))

law j_builtin_effect:
  for +name: String
  Bool

@unsafe
def j_builtin_effect(name):
  String.contains("|IO.print|IO.write|IO.print_err|IO.get_env|IO.args|IO.random_u32|IO.spawn|IO.sleep|IO.now|IO.thread_count|Process.run|Chan.new|Chan.send|Chan.recv|Chan.close|File.open|File.read|File.read_bytes|File.read_at|File.size|File.write|File.write_bytes|File.close|TCP.listen|TCP.accept|TCP.connect|TCP.send|TCP.recv|TCP.send_bytes|TCP.recv_bytes|TCP.poll|UDP.bind|UDP.send_to|UDP.recv_from|UDP.poll|Socket.close|Listener.close|Window.open|Window.frame|Window.set_title|Window.grab|Window.close|Audio.open|Audio.write|Audio.close|", "|" ++ name ++ "|")

# The shared scanner resolves foreign identifiers before either backend emits.
@unsafe
def j_source_parts(+parts: List<&2,KTerm>) -> String:
  match parts:
    case Nil{}: ""
    case Con{part, rest}:
      kc(String, String.eq(tg(part), "Text"), u => nm(part), u => j_quote(nm(part))) ++ j_source_parts(rest)
