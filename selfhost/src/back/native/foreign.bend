# A foreign source names its own module's constructors locally. Surround the C
# text with scoped aliases to the qualified constructor IDs in this program.
@unsafe
def nc_foreign_has(paths: List<&2, KTerm>, +path: String) -> Bool:
  match paths:
    case Nil{}: False{}
    case Con{h, rest}: String.eq(nm(h), path) || nc_foreign_has(rest, path)

@unsafe
def nc_source_has_id(+source: String, +name: String) -> Bool:
  String.contains(source, name ++ ",") || String.contains(source, name ++ ")") || String.contains(source, name ++ " ") || String.contains(source, name ++ "\n") || String.contains(source, name ++ "\t") || String.contains(source, name ++ ";") || String.contains(source, name ++ "]")

@unsafe
def nc_source_namespace(+parts: List<&2, String>, +prefix: String, +source: String) -> String:
  match parts:
    case Nil{}: ""
    case Con{+h, +rest}:
      nt_choose(String, nc_source_has_id(source, nt_cid(nt_join(parts, "."))), u => prefix, u => nc_source_namespace(rest, prefix ++ h ++ ".", source))

@unsafe
def nc_foreign_namespace(ds: List<&2, KDef>, +path: String, +source: String) -> String:
  match ds:
    case Nil{}: ""
    case Con{+d, +rest}:
      nt_choose(String, nc_foreign_has(ks(nc_unann(dv(d))), path),
        u => nt_choose(String, String.eq(nm(nc_unann(dv(d))), ""), u => nc_source_namespace(String.split(dn(d), '.'), "", source), u => String.take(dn(d), Nat.sub(String.length(dn(d)), String.length(nm(nc_unann(dv(d))))))),
        u => nc_foreign_namespace(rest, path, source))

@unsafe
def nc_foreign_aliases(cs: List<&2, N_Constructor>, +ns: String, +open: Bool) -> String:
  match cs:
    case Nil{}: ""
    case Con{N_Constructor{+name, a, h}, rest}:
      nt_choose(String, String.starts_with(nc_ctor_display(name), ns) && Bool.not(String.eq(nt_cid(String.drop(nc_ctor_display(name), String.length(ns))), nt_cid(name))),
        u => nt_choose(String, open,
          u => "#pragma push_macro(\"" ++ nt_cid(String.drop(nc_ctor_display(name), String.length(ns))) ++ "\")\n#define " ++ nt_cid(String.drop(nc_ctor_display(name), String.length(ns))) ++ " " ++ nt_cid(name) ++ "\n",
          u => "#pragma pop_macro(\"" ++ nt_cid(String.drop(nc_ctor_display(name), String.length(ns))) ++ "\")\n"),
        u => "") ++ nc_foreign_aliases(rest, ns, open)

@unsafe
def nc_foreign_wrap(+cs: List<&2, N_Constructor>, +ns: String, +source: String) -> String:
  nc_foreign_aliases(cs, ns, True{}) ++ source ++ "\n" ++ nc_foreign_aliases(cs, ns, False{})

@unsafe
def nc_foreign_base(ds: List<&2, KDef>, +path: String) -> Bool:
  match ds:
    case Nil{}: False{}
    case Con{+d, +rest}:
      nt_choose(Bool, nc_foreign_has(ks(nc_unann(dv(d))), path), u => db(d), u => nc_foreign_base(rest, path))

@unsafe
def nc_foreign_parts(+book: List<&2, KDef>, parts: List<&2, KTerm>) -> String:
  match parts:
    case Nil{}: ""
    case Con{+h, rest}:
      nt_choose(String, String.eq(tg(h), "Text"), u => nm(h),
        u => nt_choose(String, String.eq(tg(h), "FID"), u => nt_fid(nc_ref_name(book, nm(h))),
          u => nt_cid(nt_choose(String, String.eq(dk(lookup(book, nm(h))), "Def"), u => nm(h), u => nc_ctor_identity(book, nm(h)))))) ++ nc_foreign_parts(book, rest)

@unsafe
def nc_foreign_source(+book: List<&2, KDef>, +scope: List<&2, KDef>, +path: String, +source: String, parsed: KF_Source) -> String:
  match parsed:
    case KF_Source{+parts, +error}:
      nt_choose(String, String.eq(error, ""),
        u => nt_choose(String, nc_foreign_base(scope, path), u => nc_foreign_parts(book, parts),
          u => nc_foreign_wrap(nc_constructors(book, book), nc_foreign_namespace(scope, path, source), nc_foreign_parts(book, parts))),
        u => "#error invalid foreign source identifier\n")

# Exactly the definition closure used by nc_foreign_paths; types and all other
# definitions remain in the separate full context for identifier resolution.
@unsafe
def nc_foreign_scope(+book: List<&2, KDef>) -> List<&2, KDef>:
  kr_filter(book, nc_live_names(book, ["main"], Nil{}))
