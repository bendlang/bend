# Readback descriptor construction. A breadth-first worklist assigns a symbolic
# cell offset to every instantiated type, including recursive datatypes.
type NC_Desc is Data:
  NC_Desc{+cells: List<&2, String>, +types: List<&2, KTerm>, +error: String}

type NC_Show is Data:
  NC_Show{+source: String, +error: String}

law nc_show_nodes:
  for +book: List<&2, KDef>
  for +types: List<&2, KTerm>
  for +i: U32
  for +offset: U32
  for +defs: String
  for +cells: List<&2, String>
  NC_Show

law nc_show_field:
  for +book: List<&2, KDef>
  for +tel: KTerm
  for +left: U32
  for +i: U32
  for +d: NC_Desc
  NC_Desc

law nc_show_arm:
  for +book: List<&2, KDef>
  for +c: KDef
  for +rest: List<&2, KDef>
  for +args: List<&2, KTerm>
  for +d: NC_Desc
  NC_Desc

@unsafe
def nc_show_find(+book: List<&2, KDef>, +ty: KTerm, types: List<&2, KTerm>, +i: U32) -> U32:
  match types:
    case Nil{}: 4294967295
    case Con{h, +rest}: nt_choose(U32, norm_compare(book, ty, h, False{}, 4000000000), u => i, u => nc_show_find(book, ty, rest, U32.inc(i)))

@unsafe
def nc_show_ref(+book: List<&2, KDef>, +ty: KTerm, +types: List<&2, KTerm>) -> NC_Desc:
  +id = nc_show_find(book, ty, types, 0)
  nt_choose(NC_Desc, U32.is_eq(id, 4294967295),
    u => NC_Desc{["SD_" ++ U32.show(terms_len(types))], List.append(&2, KTerm, types, [ty]), ""},
    u => NC_Desc{["SD_" ++ U32.show(id)], types, ""})

@unsafe
def nc_desc_cells(d: NC_Desc) -> List<&2, String>:
  match d:
    case NC_Desc{cells, types, err}: cells

@unsafe
def nc_desc_types(d: NC_Desc) -> List<&2, KTerm>:
  match d:
    case NC_Desc{cells, types, err}: types

@unsafe
def nc_desc_error(d: NC_Desc) -> String:
  match d:
    case NC_Desc{cells, types, err}: err

@unsafe
def nc_desc_join(+a: NC_Desc, +b: NC_Desc) -> NC_Desc:
  NC_Desc{List.append(&2, String, nc_desc_cells(a), nc_desc_cells(b)), nc_desc_types(b), nt_choose(String, String.eq(nc_desc_error(a), ""), u => nc_desc_error(b), u => nc_desc_error(a))}

@unsafe
def nc_show_fields(
  +book: List<&2, KDef>,
  +tel: KTerm,
  +left: U32,
  +i: U32,
  +types: List<&2, KTerm>,
) -> NC_Desc:
  nt_choose(NC_Desc, U32.is_eq(left, 0), u => NC_Desc{Nil{}, types, ""}, u =>
    nt_choose(NC_Desc, U32.is_eq(qt(wnf(book, tel)), 0), u => NC_Desc{Nil{}, types, "native readback cannot print an erased field"}, u =>
      nc_show_field(book, wnf(book, tel), left, i, nc_show_ref(book, kid(wnf(book, tel), 0), types))))

@unsafe
def nc_show_field(book, tel, left, i, d):
  nc_desc_join(NC_Desc{Con{U32.show(i), nc_desc_cells(d)}, nc_desc_types(d), nc_desc_error(d)}, nc_show_fields(book, kid(tel, 1), U32.sub(left, 1), U32.inc(i), nc_desc_types(d)))

@unsafe
def nc_show_arms(
  +book: List<&2, KDef>,
  +cs: List<&2, KDef>,
  +args: List<&2, KTerm>,
  +types: List<&2, KTerm>,
) -> NC_Desc:
  match cs:
    case Nil{}: NC_Desc{Nil{}, types, ""}
    case Con{+c, rest}: nc_show_arm(book, c, rest, args, nc_show_fields(book, nc_tele_fill(book, dt(c), args), da(c), 0, types))

@unsafe
def nc_show_arm(book, c, rest, args, d):
  nc_desc_join(NC_Desc{Con{nt_cid(nc_ctor_identity(book, dn(c))), Con{nt_cid(nc_ctor_identity(book, dn(c))), Con{U32.show(da(c)), nc_desc_cells(d)}}}, nc_desc_types(d), nc_desc_error(d)}, nc_show_arms(book, rest, args, nc_desc_types(d)))

@unsafe
def nc_show_data(+book: List<&2, KDef>, +ty: KTerm, +types: List<&2, KTerm>) -> NC_Desc:
  +cs = dc(lookup(book, nm(ty)))
  +d = nc_show_arms(book, cs, ks(ty), types)
  NC_Desc{Con{"7", Con{"1", Con{U32.show(nt_count(KDef, cs)), nc_desc_cells(d)}}}, nc_desc_types(d), nc_desc_error(d)}

@unsafe
def nc_show_array(+d: NC_Desc) -> NC_Desc:
  NC_Desc{Con{"6", List.append(&2, String, nc_desc_cells(d), ["0"])}, nc_desc_types(d), nc_desc_error(d)}

@unsafe
def nc_show_node(+book: List<&2, KDef>, +ty: KTerm, +types: List<&2, KTerm>) -> NC_Desc:
  +k = nt_choose(String, db(lookup(book, nm(ty))), u => nm(ty), u => "")
  nt_choose(NC_Desc, String.eq(k, "U32"), u => NC_Desc{["0"], types, ""}, u =>
  nt_choose(NC_Desc, String.eq(k, "F32"), u => NC_Desc{["1"], types, ""}, u =>
  nt_choose(NC_Desc, String.eq(k, "Nat"), u => NC_Desc{["2"], types, ""}, u =>
  nt_choose(NC_Desc, String.eq(k, "Char"), u => NC_Desc{["3", "0"], types, ""}, u =>
  nt_choose(NC_Desc, String.eq(k, "String"), u => NC_Desc{["4"], types, ""}, u =>
  nt_choose(NC_Desc, String.eq(k, "Bool"), u => NC_Desc{["7", "0", "2", "CID_FALSE", "CID_FALSE", "0", "CID_TRUE", "CID_TRUE", "0"], types, ""}, u =>
  nt_choose(NC_Desc, String.eq(tg(ty), "Eql"), u => NC_Desc{["5"], types, ""}, u =>
  nt_choose(NC_Desc, String.eq(k, "Array"), u => nc_show_array(nc_show_ref(book, kid(ty, 0), types)), u =>
  nt_choose(NC_Desc, String.eq(tg(ty), "ADT") && String.eq(dk(lookup(book, nm(ty))), "ADT") && Bool.not(String.eq(k, "IO.OP")), u => nc_show_data(book, ty, types), u =>
    NC_Desc{Nil{}, types, "native readback cannot print a function, type, or dependent field"})))))))))

@unsafe
def nc_show_step(+book: List<&2, KDef>, +i: U32, +offset: U32, +defs: String, +cells: List<&2, String>, +d: NC_Desc) -> NC_Show:
  nt_choose(NC_Show, String.eq(nc_desc_error(d), ""),
    u => nc_show_nodes(book, nc_desc_types(d), U32.inc(i), U32.add(offset, nt_count(String, nc_desc_cells(d))), defs ++ "#define SD_" ++ U32.show(i) ++ " " ++ U32.show(offset) ++ "\n", List.append(&2, String, cells, nc_desc_cells(d))),
    u => NC_Show{"", nc_desc_error(d)})

@unsafe
def nc_show_nodes(book, types, i, offset, defs, cells):
  nt_choose(NC_Show, U32.is_eq(i, terms_len(types)), u => NC_Show{defs ++ "static const u32 SHOW_DESC[] = { " ++ nt_join(cells, ", ") ++ " };\n", ""}, u =>
    nt_choose(NC_Show, U32.is_gt(i, 4096), u => NC_Show{"", "native readback type graph exceeds 4096 nodes"}, u =>
      nc_show_step(book, i, offset, defs, cells, nc_show_node(book, wnf(book, terms_at(types, i)), types))))

@unsafe
def nc_quote_chars(s: String) -> String:
  match s:
    case SNil{}: ""
    case SCon{+h, t}: nt_choose(String, Char.is_eq(h, '"'), u => "\\\"", u => nt_choose(String, Char.is_eq(h, '\\'), u => "\\\\", u => SCon{h, ""})) ++ nc_quote_chars(t)

@unsafe
def nc_show_names(cs: List<&2, N_Constructor>) -> List<&2, String>:
  match cs:
    case Nil{}: Nil{}
    case Con{N_Constructor{k, a, h}, rest}: Con{"\"" ++ nc_quote_chars(nc_ctor_display(k)) ++ "\"", nc_show_names(rest)}

@unsafe
def nc_show_finish(cs: List<&2, N_Constructor>, d: NC_Show) -> NC_Show:
  match d:
    case NC_Show{src, err}: NC_Show{"#if !DEVICE\n" ++ src ++ "static const char* SHOW_NAMES[] = { " ++ nt_join(nc_show_names(cs), ", ") ++ " };\n#endif\n", err}

@unsafe
def nc_show_program(+book: List<&2, KDef>, ty: KTerm, cs: List<&2, N_Constructor>) -> NC_Show:
  nc_show_finish(cs, nc_show_nodes(book, [ty], 0, 0, "", Nil{}))
