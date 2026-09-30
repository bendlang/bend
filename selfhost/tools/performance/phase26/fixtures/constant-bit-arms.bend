# Extend upstream u32_table_bitvar across the full unsigned domain, with ignored
# bit bindings and a two-bit prefix returning constants.
import Base

def odd(n: U32) -> U32:
  match n:
    case 0: 10
    case 1: 11
    case U32{WCon{True{}, r}}: 12
    case _: 13

def catch(n: U32) -> U32:
  match n:
    case 0: 10
    case 1: 11
    case U32{WCon{b, r}}: 12
    case _: 13

def low(n: U32) -> U32:
  match n:
    case 0: 179
    case U32{WCon{True{}, WCon{False{}, r}}}: 163
    case U32{WCon{False{}, WCon{True{}, r}}}: 167
    case _: 173

def bench(+n: U32, seed: U32) -> U32:
  U32.add(U32.add(U32.mul(odd(n), 257), U32.mul(catch(n), 17)), U32.add(low(n), seed))
