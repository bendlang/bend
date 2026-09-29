type ni_Op is Data:
  ni_Op{+name: String, +template: String}

@unsafe
def ni_templates() -> List<&2, ni_Op>:
  Con{ni_Op{"u32_add", "U32_BIN($0, +, $1)"}, Con{ni_Op{"u32_sub", "U32_BIN($0, -, $1)"}, Con{ni_Op{"u32_and", "U32_BIN($0, &, $1)"}, Con{ni_Op{"u32_or", "U32_BIN($0, |, $1)"}, Con{ni_Op{"u32_xor", "U32_BIN($0, ^, $1)"}, Con{ni_Op{"u32_mul", "U32_BIN($0, *, $1)"}, Con{ni_Op{"u32_is_eq", "U32_BIN($0, ==, $1)"}, Con{ni_Op{"u32_is_ne", "U32_BIN($0, !=, $1)"}, Con{ni_Op{"u32_is_lt", "U32_BIN($0, <, $1)"}, Con{ni_Op{"u32_is_le", "U32_BIN($0, <=, $1)"}, Con{ni_Op{"u32_is_gt", "U32_BIN($0, >, $1)"}, Con{ni_Op{"u32_is_ge", "U32_BIN($0, >=, $1)"}, Con{ni_Op{"u32_inc", "U32_BIN($0, +, 1)"}, Con{ni_Op{"u32_shl", "U32_BIN($0, <<, 1)"}, Con{ni_Op{"u32_shr", "U32_BIN($0, >>, 1)"}, Con{ni_Op{"u32_shln", "($1 >= 32 ? 0 : U32_BIN($0, <<, $1))"}, Con{ni_Op{"u32_shrn", "($1 >= 32 ? 0 : U32_BIN($0, >>, $1))"}, Con{ni_Op{"u32_div", "((u32)($1) == 0 ? 0 : (u64)U32_QUO((u32)($0), (u32)($1)))"}, Con{ni_Op{"u32_mod", "((u32)($1) == 0 ? $0 : U32_BIN($0, -, U32_QUO((u32)($0), (u32)($1)) * $1))"}, Con{ni_Op{"u32_not", "((u64)~(u32)($0))"}, Con{ni_Op{"u32_is_zero", "U32_BIN($0, ==, 0)"}, Con{ni_Op{"u32_cmp", "(U32_BIN($0, >, $1) + U32_BIN($0, >=, $1))"}, Con{ni_Op{"u32_to_f32", "f32_rewrap((f32)(u32)($0))"}, Con{ni_Op{"u32_to_nat", "((u64)$0)"}, Con{ni_Op{"u32_from_nat", "((u64)(u32)($0))"}, Con{ni_Op{"f32_add", "f32_rewrap(f32_unbox($0) + f32_unbox($1))"}, Con{ni_Op{"f32_sub", "f32_rewrap(f32_unbox($0) - f32_unbox($1))"}, Con{ni_Op{"f32_mul", "f32_rewrap(f32_unbox($0) * f32_unbox($1))"}, Con{ni_Op{"f32_div", "f32_rewrap(f32_unbox($0) / f32_unbox($1))"}, Con{ni_Op{"f32_is_eq", "((u64)(f32_unbox($0) == f32_unbox($1)))"}, Con{ni_Op{"f32_is_ne", "((u64)(f32_unbox($0) != f32_unbox($1)))"}, Con{ni_Op{"f32_is_lt", "((u64)(f32_unbox($0) < f32_unbox($1)))"}, Con{ni_Op{"f32_is_le", "((u64)(f32_unbox($0) <= f32_unbox($1)))"}, Con{ni_Op{"f32_is_gt", "((u64)(f32_unbox($0) > f32_unbox($1)))"}, Con{ni_Op{"f32_is_ge", "((u64)(f32_unbox($0) >= f32_unbox($1)))"}, Con{ni_Op{"f32_sqrt", "f32_rewrap((f32)sqrt(f32_unbox($0)))"}, Con{ni_Op{"f32_exp", "f32_rewrap((f32)exp(f32_unbox($0)))"}, Con{ni_Op{"f32_log", "f32_rewrap((f32)log(f32_unbox($0)))"}, Con{ni_Op{"f32_log2", "f32_rewrap((f32)log2(f32_unbox($0)))"}, Con{ni_Op{"f32_log10", "f32_rewrap((f32)log10(f32_unbox($0)))"}, Con{ni_Op{"f32_sin", "f32_rewrap((f32)sin(f32_unbox($0)))"}, Con{ni_Op{"f32_cos", "f32_rewrap((f32)cos(f32_unbox($0)))"}, Con{ni_Op{"f32_tan", "f32_rewrap((f32)tan(f32_unbox($0)))"}, Con{ni_Op{"f32_asin", "f32_rewrap((f32)asin(f32_unbox($0)))"}, Con{ni_Op{"f32_acos", "f32_rewrap((f32)acos(f32_unbox($0)))"}, Con{ni_Op{"f32_atan", "f32_rewrap((f32)atan(f32_unbox($0)))"}, Con{ni_Op{"f32_sinh", "f32_rewrap((f32)sinh(f32_unbox($0)))"}, Con{ni_Op{"f32_cosh", "f32_rewrap((f32)cosh(f32_unbox($0)))"}, Con{ni_Op{"f32_tanh", "f32_rewrap((f32)tanh(f32_unbox($0)))"}, Con{ni_Op{"f32_floor", "f32_rewrap((f32)floor(f32_unbox($0)))"}, Con{ni_Op{"f32_ceil", "f32_rewrap((f32)ceil(f32_unbox($0)))"}, Con{ni_Op{"f32_trunc", "f32_rewrap((f32)trunc(f32_unbox($0)))"}, Con{ni_Op{"f32_abs", "f32_rewrap((f32)fabs(f32_unbox($0)))"}, Con{ni_Op{"f32_pow", "f32_rewrap((f32)pow(f32_unbox($0), f32_unbox($1)))"}, Con{ni_Op{"f32_atan2", "f32_rewrap((f32)atan2(f32_unbox($0), f32_unbox($1)))"}, Con{ni_Op{"f32_mod", "f32_rewrap((f32)fmod(f32_unbox($0), f32_unbox($1)))"}, Con{ni_Op{"f32_neg", "f32_rewrap(-f32_unbox($0))"}, Con{ni_Op{"f32_to_u32", "f32_to_u32($0)"}, Con{ni_Op{"f32_bits", "$0"}, Con{ni_Op{"f32_show", "f32_show(e, $0)"}, Con{ni_Op{"f32_read", "f32_read(e, $0)"}, Con{ni_Op{"nat_add", "nat_chk(e, $0 + $1)"}, Con{ni_Op{"nat_sub", "($0 < $1 ? 0 : $0 - $1)"}, Con{ni_Op{"nat_mul", "nat_mul(e, $0, $1)"}, Con{ni_Op{"nat_double", "nat_chk(e, $0 + $0)"}, Con{ni_Op{"nat_cmp", "(($0 > $1) + ($0 >= $1))"}, Con{ni_Op{"nat_is_lt", "($0 < $1)"}, Con{ni_Op{"bool_or", "(native_bool($0) | native_bool($1))"}, Con{ni_Op{"bool_xor", "(native_bool($0) ^ native_bool($1))"}, Nil{}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}}

@unsafe
def ni_find(+k: String, ops: List<&2, ni_Op>) -> String:
  match ops:
    case Nil{}: ""
    case Con{ni_Op{n, +t}, +rest}: nt_choose(String, String.eq(k, n), u => t, u => ni_find(k, rest))

@unsafe
def ni_replace_all(+s: String, +key: String, +value: String) -> String:
  match s:
    case SNil{}: ""
    case SCon{+h, +t}:
      nt_choose(String, String.starts_with(s, key), u => value ++ ni_replace_all(String.drop(s, String.length(key)), key, value), u => SCon{h, ni_replace_all(t, key, value)})

@unsafe
def ni_fill(+s: String, xs: List<&2, String>, +i: U32) -> String:
  match xs:
    case Nil{}: s
    case Con{h, t}: ni_fill(ni_replace_all(s, "$" ++ U32.show(i), h), t, U32.inc(i))

@unsafe
def ni_emit(k: String, xs: List<&2, String>) -> String:
  ni_fill(ni_find(k, ni_templates()), xs, 0)
