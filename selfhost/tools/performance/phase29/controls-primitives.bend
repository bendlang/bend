# Phase29 independently specified checked primitive and ABI controls.
import Base

@unsafe
def u32_add(+x: U32, +y: U32) -> U32:
  U32.add(x, y)

@unsafe
def u32_sub(+x: U32, +y: U32) -> U32:
  U32.sub(x, y)

@unsafe
def u32_mul(+x: U32, +y: U32) -> U32:
  U32.mul(x, y)

@unsafe
def u32_div(+x: U32, +y: U32) -> U32:
  U32.div(x, y)

@unsafe
def u32_mod(+x: U32, +y: U32) -> U32:
  U32.mod(x, y)

@unsafe
def u32_and(+x: U32, +y: U32) -> U32:
  U32.and(x, y)

@unsafe
def u32_or(+x: U32, +y: U32) -> U32:
  U32.or(x, y)

@unsafe
def u32_xor(+x: U32, +y: U32) -> U32:
  U32.xor(x, y)

@unsafe
def u32_inc(+x: U32) -> U32:
  U32.inc(x)

@unsafe
def u32_not(+x: U32) -> U32:
  U32.not(x)

@unsafe
def u32_shl(+x: U32) -> U32:
  U32.shl(x)

@unsafe
def u32_shr(+x: U32) -> U32:
  U32.shr(x)

@unsafe
def u32_shln(+x: U32, +y: Nat) -> U32:
  U32.shln(x, y)

@unsafe
def u32_shrn(+x: U32, +y: Nat) -> U32:
  U32.shrn(x, y)

@unsafe
def u32_is_zero(+x: U32) -> Bool:
  U32.is_zero(x)

@unsafe
def u32_is_eq(+x: U32, +y: U32) -> Bool:
  U32.is_eq(x, y)

@unsafe
def u32_is_ne(+x: U32, +y: U32) -> Bool:
  U32.is_ne(x, y)

@unsafe
def u32_is_lt(+x: U32, +y: U32) -> Bool:
  U32.is_lt(x, y)

@unsafe
def u32_is_le(+x: U32, +y: U32) -> Bool:
  U32.is_le(x, y)

@unsafe
def u32_is_gt(+x: U32, +y: U32) -> Bool:
  U32.is_gt(x, y)

@unsafe
def u32_is_ge(+x: U32, +y: U32) -> Bool:
  U32.is_ge(x, y)

@unsafe
def u32_to_nat(+x: U32) -> Nat:
  U32.to_nat(x)

@unsafe
def u32_from_nat(+x: Nat) -> U32:
  U32.from_nat(x)

@unsafe
def u32_to_f32(+x: U32) -> F32:
  U32.to_f32(x)

@unsafe
def f32_add(+x: F32, +y: F32) -> F32:
  F32.add(x, y)

@unsafe
def f32_sub(+x: F32, +y: F32) -> F32:
  F32.sub(x, y)

@unsafe
def f32_mul(+x: F32, +y: F32) -> F32:
  F32.mul(x, y)

@unsafe
def f32_div(+x: F32, +y: F32) -> F32:
  F32.div(x, y)

@unsafe
def f32_mod(+x: F32, +y: F32) -> F32:
  F32.mod(x, y)

@unsafe
def f32_is_eq(+x: F32, +y: F32) -> Bool:
  F32.is_eq(x, y)

@unsafe
def f32_is_ne(+x: F32, +y: F32) -> Bool:
  F32.is_ne(x, y)

@unsafe
def f32_is_lt(+x: F32, +y: F32) -> Bool:
  F32.is_lt(x, y)

@unsafe
def f32_is_le(+x: F32, +y: F32) -> Bool:
  F32.is_le(x, y)

@unsafe
def f32_is_gt(+x: F32, +y: F32) -> Bool:
  F32.is_gt(x, y)

@unsafe
def f32_is_ge(+x: F32, +y: F32) -> Bool:
  F32.is_ge(x, y)

@unsafe
def f32_neg(+x: F32) -> F32:
  F32.neg(x)

@unsafe
def f32_sqrt(+x: F32) -> F32:
  F32.sqrt(x)

@unsafe
def f32_exp(+x: F32) -> F32:
  F32.exp(x)

@unsafe
def f32_log(+x: F32) -> F32:
  F32.log(x)

@unsafe
def f32_log2(+x: F32) -> F32:
  F32.log2(x)

@unsafe
def f32_log10(+x: F32) -> F32:
  F32.log10(x)

@unsafe
def f32_sin(+x: F32) -> F32:
  F32.sin(x)

@unsafe
def f32_cos(+x: F32) -> F32:
  F32.cos(x)

@unsafe
def f32_tan(+x: F32) -> F32:
  F32.tan(x)

@unsafe
def f32_asin(+x: F32) -> F32:
  F32.asin(x)

@unsafe
def f32_acos(+x: F32) -> F32:
  F32.acos(x)

@unsafe
def f32_atan(+x: F32) -> F32:
  F32.atan(x)

@unsafe
def f32_sinh(+x: F32) -> F32:
  F32.sinh(x)

@unsafe
def f32_cosh(+x: F32) -> F32:
  F32.cosh(x)

@unsafe
def f32_tanh(+x: F32) -> F32:
  F32.tanh(x)

@unsafe
def f32_floor(+x: F32) -> F32:
  F32.floor(x)

@unsafe
def f32_ceil(+x: F32) -> F32:
  F32.ceil(x)

@unsafe
def f32_trunc(+x: F32) -> F32:
  F32.trunc(x)

@unsafe
def f32_abs(+x: F32) -> F32:
  F32.abs(x)

@unsafe
def partial_add(+x: U32, +y: U32) -> U32:
  f = U32.add(x)
  f(y)

@unsafe
def partial_shift(+x: U32, +n: Nat) -> U32:
  f = U32.shln(x)
  f(n)

@unsafe
def apply_twice(+f: U32 -> U32, +x: U32) -> U32:
  f(f(x))

@unsafe
def higher_order_add(+x: U32, +y: U32) -> U32:
  apply_twice(U32.add(x), y)

@unsafe
def tail_count(+n: U32, +acc: U32) -> U32:
  match n:
    case 0: acc
    case other: tail_count(U32.sub(other, 1), U32.inc(acc))
