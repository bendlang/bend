@unsafe
def nb_max(+a: U32, +b: U32) -> U32:
  nt_choose(U32, U32.is_gt(a, b), u => a, u => b)

@unsafe
def nb_width_go(ss: List<&2, N_Segment>, +acc: U32) -> U32:
  match ss:
    case Nil{}: acc
    case Con{N_Segment{+k, +ps, +r, +f, +b, +refs, +h, +s, +fork, +bang}, t}: nb_width_go(t, nb_max(acc, nb_max(nt_count(N_Param, ps), r)))

@unsafe
def nb_width(ss: List<&2, N_Segment>) -> U32:
  nb_width_go(ss, 2)

@unsafe
def nb_returns_go(ss: List<&2, N_Segment>, +acc: U32) -> U32:
  match ss:
    case Nil{}: acc
    case Con{N_Segment{+k, +ps, +r, +f, +b, +refs, +h, +s, +fork, +bang}, t}: nb_returns_go(t, nb_max(acc, r))

@unsafe
def nb_returns(ss: List<&2, N_Segment>) -> U32:
  nb_returns_go(ss, 1)

@unsafe
def nb_bangs_go(ss: List<&2, N_Segment>, +acc: U32) -> U32:
  match ss:
    case Nil{}: acc
    case Con{N_Segment{+k, +ps, +r, +f, +b, +refs, +h, +s, +fork, +bang}, t}: nb_bangs_go(t, U32.add(acc, nt_bool(bang)))

@unsafe
def nb_bangs(ss: List<&2, N_Segment>) -> U32:
  nb_bangs_go(ss, 0)

@unsafe
def nb_regs(+n: U32, +i: U32) -> List<&2, String>:
  match n:
    case 0: Nil{}
    case _: Con{"r" ++ U32.show(i), nb_regs(U32.sub(n, 1), U32.inc(i))}

@unsafe
def nb_pad(+rs: List<&2, String>, +i: U32) -> List<&2, String>:
  match rs:
    case Nil{}: Nil{}
    case Con{+h, +t}: nt_choose(List<&2, String>, U32.is_eq(i, 6), u => Con{"rp", Con{h, t}}, u => Con{h, nb_pad(t, U32.inc(i))})

@unsafe
def nb_typed(+rs: List<&2, String>) -> List<&2, String>:
  match rs:
    case Nil{}: Nil{}
    case Con{+h, +t}: Con{"Term " ++ h, nb_typed(t)}

@unsafe
def nb_load(+rs: List<&2, String>, +i: U32) -> String:
  match rs:
    case Nil{}: ""
    case Con{+h, +t}: "    if ((N) <= " ++ U32.show(i) ++ ") break; " ++ h ++ " = e.mem[(A) + " ++ U32.show(i) ++ "]; \\\n" ++ nb_load(t, U32.inc(i))

@unsafe
def nb_last(+rs: List<&2, String>, +i: U32) -> String:
  match rs:
    case Nil{}: ""
    case Con{+h, +t}: "    case " ++ U32.show(i) ++ ": " ++ h ++ " = (X); break; \\\n" ++ nb_last(t, U32.inc(i))

@unsafe
def nb_save(+rs: List<&2, String>, +i: U32) -> String:
  match rs:
    case Nil{}: ""
    case Con{+h, +t}: "(V)[" ++ U32.show(i) ++ "] = " ++ h ++ "; " ++ nb_save(t, U32.inc(i))

@unsafe
def nb_take(+rs: List<&2, String>, +i: U32) -> String:
  match rs:
    case Nil{}: ""
    case Con{+h, +t}: h ++ " = (V)[" ++ U32.show(i) ++ "]; " ++ nb_take(t, U32.inc(i))

@unsafe
def nb_bank(+ss: List<&2, N_Segment>) -> String:
  +n = nb_width(ss)
  +r = nb_returns(ss)
  +rs = nb_regs(n, 0)
  +ws = nb_pad(rs, 0)
  "#define WL_RESW " ++ U32.show(r) ++ "\n#define BANGS " ++ U32.show(nb_bangs(ss)) ++ "\n#define WL_BANK Term " ++ nt_join(ws, ", ") ++ ";\n"
    ++ "#define WL_LOAD(A, N) \\\n  do { \\\n" ++ nb_load(rs, 0) ++ "  } while (0);\n"
    ++ "#define WL_LAST(X) \\\n  switch (war) { \\\n" ++ nb_last(rs, 0) ++ "  }\n"
    ++ "#define WL_SAVE(V) " ++ nb_save(nb_regs(r, 0), 0) ++ "\n"
    ++ "#define WL_TAKE(V) " ++ nb_take(nb_regs(r, 0), 0) ++ "\n"
    ++ "#define WL_SIG Env e, Stk sp, u32 seq, u32 rn, " ++ nt_join(nb_typed(ws), ", ") ++ "\n"
    ++ "#define WL_ALL e, sp, seq, rn, " ++ nt_join(ws, ", ") ++ "\n"

@unsafe
def nb_seg_ids_go(ss: List<&2, N_Segment>, +i: U32, +acc: String) -> String:
  match ss:
    case Nil{}: acc ++ "#define FID_IO_EMIT " ++ U32.show(i) ++ "\n#define BEND_CLO_APPLY " ++ U32.show(U32.add(i, 1)) ++ "\n#define FID_EXIT " ++ U32.show(U32.add(i, 2)) ++ "\n#define FID_ENTER " ++ U32.show(U32.add(i, 3)) ++ "\n"
    case Con{N_Segment{+k, +ps, +r, +f, +b, +refs, +h, +s, +fork, +bang}, t}: nb_seg_ids_go(t, U32.inc(i), acc ++ "#define " ++ nt_fid(k) ++ " " ++ U32.show(i) ++ "\n")

@unsafe
def nb_seg_ids(ss: List<&2, N_Segment>, i: U32) -> String:
  nb_seg_ids_go(ss, i, "")

@unsafe
def nb_ctr_ids(+cs: List<&2, N_Constructor>, +i: U32) -> String:
  match cs:
    case Nil{}: ""
    case Con{N_Constructor{+k, +a, +h}, +t}: "#define " ++ nt_cid(k) ++ " " ++ U32.show(i) ++ "\n" ++ nb_ctr_ids(t, U32.inc(i))

@unsafe
def nb_frame_results(+f: N_Frame, +n: U32) -> U32:
  match f:
    case N_Direct{}: 0
    case N_Frame{+pop, +at}: U32.sub(n, nt_count(String, at))

@unsafe
def nb_arities_go(ss: List<&2, N_Segment>, +acc: String) -> String:
  match ss:
    case Nil{}: acc ++ "1, 2"
    case Con{N_Segment{+k, +ps, +r, +f, +b, +refs, +h, +s, +fork, +bang}, t}: nb_arities_go(t, acc ++ U32.show(nt_count(N_Param, ps)) ++ ", ")

@unsafe
def nb_arities(ss: List<&2, N_Segment>) -> String:
  nb_arities_go(ss, "")

@unsafe
def nb_result_words_go(ss: List<&2, N_Segment>, +acc: String) -> String:
  match ss:
    case Nil{}: acc ++ "0, 0"
    case Con{N_Segment{+k, +ps, +r, +f, +b, +refs, +h, +s, +fork, +bang}, t}: nb_result_words_go(t, acc ++ U32.show(nb_frame_results(f, nt_count(N_Param, ps))) ++ ", ")

@unsafe
def nb_result_words(ss: List<&2, N_Segment>) -> String:
  nb_result_words_go(ss, "")

@unsafe
def nb_contains(+xs: List<&2, String>, +k: String) -> Bool:
  match xs:
    case Nil{}: False{}
    case Con{+h, +t}: String.eq(h, k) || nb_contains(t, k)

@unsafe
def nb_fork_roots_go(ss: List<&2, N_Segment>, +acc: List<&2, String>) -> List<&2, String>:
  match ss:
    case Nil{}: acc
    case Con{N_Segment{+k, +ps, +r, +f, +b, +refs, +h, +s, +fork, +bang}, t}: nb_fork_roots_go(t, nt_choose(List<&2, String>, fork, u => Con{k, acc}, u => acc))

@unsafe
def nb_fork_roots(ss: List<&2, N_Segment>) -> List<&2, String>:
  nb_fork_roots_go(ss, Nil{})

@unsafe
def nb_reaches(+xs: List<&2, String>, +roots: List<&2, String>) -> Bool:
  match xs:
    case Nil{}: False{}
    case Con{+h, +t}: nb_contains(roots, h) || nb_reaches(t, roots)

@unsafe
def nb_fork_step(+ss: List<&2, N_Segment>, +roots: List<&2, String>) -> List<&2, String>:
  match ss:
    case Nil{}: roots
    case Con{N_Segment{+k, +ps, +r, +f, +b, +refs, +h, +s, +fork, +bang}, +t}:
      nb_fork_step(t, nt_choose(List<&2, String>, fork, u => roots, u => nt_choose(List<&2, String>, Bool.not(nb_contains(roots, k)) && nb_reaches(refs, roots), u => Con{k, roots}, u => roots)))

law nb_fork_next:
  for +ss: List<&2, N_Segment>
  for +roots: List<&2, String>
  for +next: List<&2, String>
  for +fuel: U32
  List<&2, String>

@unsafe
def nb_fork_close(+ss: List<&2, N_Segment>, +roots: List<&2, String>, +fuel: U32) -> List<&2, String>:
  match fuel:
    case 0: roots
    case _: nb_fork_next(ss, roots, nb_fork_step(ss, roots), U32.sub(fuel, 1))

@unsafe
def nb_fork_next(ss, roots, next, fuel):
  nt_choose(List<&2, String>, U32.is_eq(nt_count(String, roots), nt_count(String, next)), u => next, u => nb_fork_close(ss, next, fuel))

@unsafe
def nb_flags_go(ss: List<&2, N_Segment>, +forks: List<&2, String>, +acc: String) -> String:
  match ss:
    case Nil{}: acc ++ "2, 0"
    case Con{N_Segment{+k, +ps, +r, +f, +b, +refs, +h, +s, +fork, +bang}, t}:
      nb_flags_go(t, forks, acc ++ U32.show(U32.add(nt_bool(bang), U32.mul(2, nt_bool(nt_choose(Bool, fork, u => False{}, u => Bool.not(nb_contains(forks, k))))))) ++ ", ")

@unsafe
def nb_flags(ss: List<&2, N_Segment>, forks: List<&2, String>) -> String:
  nb_flags_go(ss, forks, "")

@unsafe
def nb_ctr_arity(+cs: List<&2, N_Constructor>) -> String:
  match cs:
    case Nil{}: "0"
    case Con{N_Constructor{+k, +a, +h}, +t}: U32.show(a) ++ ", " ++ nb_ctr_arity(t)

@unsafe
def nb_ctr_hot(+cs: List<&2, N_Constructor>) -> String:
  match cs:
    case Nil{}: "0"
    case Con{N_Constructor{+k, +a, +h}, +t}: U32.show(nt_bool(h)) ++ ", " ++ nb_ctr_hot(t)

@unsafe
def nb_dispatch_go(ss: List<&2, N_Segment>, +acc: String) -> String:
  match ss:
    case Nil{}: acc ++ "WL_X(FID_IO_EMIT) WL_X(BEND_CLO_APPLY) WL_X(FID_EXIT)"
    case Con{N_Segment{+k, +ps, +r, +f, +b, +refs, +h, +s, +fork, +bang}, t}: nb_dispatch_go(t, acc ++ "WL_X(" ++ nt_fid(k) ++ ") ")

@unsafe
def nb_dispatch(ss: List<&2, N_Segment>) -> String:
  nb_dispatch_go(ss, "")

@unsafe
def nb_emit(+ss: List<&2, N_Segment>, +cs: List<&2, N_Constructor>, +image_size: U32, +pure: Bool) -> String:
  nb_seg_ids(ss, 0) ++ nb_ctr_ids(cs, 0) ++ nb_bank(ss)
    ++ "CONSTV u8 FID_ARITY_T[] = { " ++ nb_arities(ss) ++ " };\n"
    ++ "CONSTV u8 FID_FLAG_T[] = { " ++ nb_flags(ss, nb_fork_close(ss, nb_fork_roots(ss), nt_count(N_Segment, ss))) ++ " };\n"
    ++ "CONSTV u8 FID_RESW_T[] = { " ++ nb_result_words(ss) ++ " };\n"
    ++ "CONSTV u8 CID_ARITY_T[] = { " ++ nb_ctr_arity(cs) ++ " };\n"
    ++ "CONSTV u8 CID_HOT_T[] = { " ++ nb_ctr_hot(cs) ++ " };\n"
    ++ "#define STAT_LEN " ++ U32.show(image_size) ++ "\n#define WL_TABLE " ++ nb_dispatch(ss)
    ++ "\n#define MAIN_FID FID_MAIN\n#define MAIN_PURE " ++ U32.show(nt_bool(pure)) ++ "\n"
