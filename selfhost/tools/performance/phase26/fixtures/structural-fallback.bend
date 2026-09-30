# Derived from upstream u32_table_bitvar: bindings are used, not only discarded.
import Base

def odd(n: U32) -> U32:
  match n:
    case 0: 100
    case 1: 101
    case U32{WCon{True{}, r}}: U32{WCon{False{}, r}}
    case _: 103

def bits(n: U32, seed: U32) -> U32:
  match n:
    case 0: U32.add(seed, 107)
    case 1: U32.add(seed, 109)
    case U32{WCon{b, r}}: U32.add(U32{WCon{b, r}}, seed)
    case _: 113

def bench(+n: U32, seed: U32) -> U32:
  U32.add(odd(n), bits(n, seed))
