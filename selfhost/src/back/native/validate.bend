# Validate the runtime's 16-bit IDs and 8-bit arities before emitting C.
@unsafe
def nv_owned(book: List<&2, KDef>) -> String:
  match book:
    case Nil{}: ""
    case Con{+d, +rest}:
      nt_choose(String, Bool.not(db(d)) && nb_contains(["IO", "Sigma", "String", "Word.Con", "IO.OP", "Result", "Maybe", "Bool", "Unit", "Nat", "U32", "F32", "Char", "Array"], dn(d)),
        u => dn(d) ++ " is a name the compiler encodes itself: name yours apart",
        u => nv_owned(rest))

@unsafe
def nv_ctor_names(cs: List<&2, N_Constructor>) -> List<&2, String>:
  match cs:
    case Nil{}: Nil{}
    case Con{N_Constructor{k, a, h}, rest}: Con{nt_cid(k), nv_ctor_names(rest)}

@unsafe
def nv_seg_names_go(ss: List<&2, N_Segment>, acc: List<&2, String>) -> List<&2, String>:
  match ss:
    case Nil{}: nt_reverse(String, acc, ["FID_IO_EMIT", "BEND_CLO_APPLY", "FID_EXIT", "FID_ENTER"])
    case Con{N_Segment{k, ps, r, f, b, refs, host, spin, fork, bang}, rest}: nv_seg_names_go(rest, Con{nt_fid(k), acc})

@unsafe
def nv_seg_names(ss: List<&2, N_Segment>) -> List<&2, String>:
  nv_seg_names_go(ss, Nil{})

@unsafe
def nv_id(name: String) -> KDef:
  KDef{name, "NativeId", 0, 0, atom("Absent"), atom("Absent"), Nil{}, False{}, False{}}

@unsafe
def nv_unique_index(xs: List<&2, String>, +seen: KDef) -> String:
  match xs:
    case Nil{}: ""
    case Con{+h, +rest}:
      +hash = index_hash(h, 2166136261)
      nt_choose(String, String.eq(dk(index_find(seen, h, hash, 32)), "Absent"), u => nv_unique_index(rest, index_set(seen, nv_id(h), hash, 32)), u => "native identifier collision: " ++ h)

@unsafe
def nv_unique(xs: List<&2, String>, seen: List<&2, String>) -> String:
  nv_unique_index(List.append(&2, String, seen, xs), missing())

@unsafe
def nv_ctors(cs: List<&2, N_Constructor>) -> String:
  match cs:
    case Nil{}: ""
    case Con{N_Constructor{+k, +a, h}, +rest}: nt_choose(String, U32.is_gt(a, 255), u => "native constructor arity exceeds 255: " ++ k, u => nv_ctors(rest))

@unsafe
def nv_segs(ss: List<&2, N_Segment>) -> String:
  match ss:
    case Nil{}: ""
    case Con{N_Segment{+k, +ps, +r, f, b, refs, host, spin, fork, bang}, +rest}: nt_choose(String, U32.is_gt(nt_count(N_Param, ps), 255) || U32.is_gt(r, 255), u => "native segment arity exceeds 255: " ++ k, u => nv_segs(rest))

@unsafe
def nv_first(+a: String, +b: String) -> String:
  nt_choose(String, String.eq(a, ""), u => b, u => a)

@unsafe
def nv_program(+ss: List<&2, N_Segment>, +cs: List<&2, N_Constructor>) -> String:
  nt_choose(String, U32.is_gt(nt_count(N_Segment, ss), 65532) || U32.is_gt(nt_count(N_Constructor, cs), 65536), u => "native identifier exceeds 65535", u =>
    nv_first(nv_unique(nv_ctor_names(cs), ["CID_ARITY_T", "CID_HOT_T", "FID_ARITY_T", "FID_FLAG_T", "FID_RESW_T"]), nv_first(nv_unique(nv_seg_names(ss), Nil{}), nv_first(nv_ctors(cs), nv_segs(ss)))))
