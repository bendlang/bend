# io pin (io_json_roundtrip): bend3's JSON module -- read/show
# roundtrip with escapes and nesting, located read errors, polite
# accessors defaulting on misses. bend has no JSON module -- rt dies
# first on the missing surface (LL.get answers Maybe in bend, so
# the accessor walk rides Mb.default).
import Base

law LL.length:
  for -a: Quant
  for -A: Kind(a)
  for xs: List<a, A>
  Nat

def LL.length(a, A, xs):
  match xs:
    case Nil{}:
      0n
    case h <> t:
      1n+LL.length(a, A, t)

law nat_eq:
  for a: Nat
  for b: Nat
  Bool

def nat_eq(a, b):
  Cmp.is_eq(Nat.cmp(a, b))

law Mb.default:
  for -a: Quant
  for -A: Kind(a)
  for m: Maybe<a, A>
  for d: A
  A

def Mb.default(a, A, m, d):
  match m:
    case None{}:
      d
    case Some{x}:
      x

law LL.get:
  for -a: Quant
  for -A: Kind(a)
  for n: Nat
  for xs: List<a, A>
  Maybe<a, A>

def LL.get(a, A, n, xs):
  match n xs:
    case 0n Nil{}:
      None{}
    case 0n h <> t:
      Some{h}
    case 1n+p Nil{}:
      None{}
    case 1n+p h <> t:
      LL.get(a, A, p, t)

law b2u:
  for b: Bool
  U32

def b2u(b):
  match b:
    case True{}:
      1
    case False{}:
      0

law rt:
  for s: String
  for out: String
  U32

law rt.rd:
  for out: String
  for r: Result<&1, &1, (U32 & String), JSON>
  U32

def rt.rd(out, r):
  match r:
    case Done{j}:
      b2u(String.eq(JSON.show(j), out))
    case Fail{(p, m)}:
      0

def rt(s, out):
  rt.rd(out, JSON.read(s))

law bad:
  for s: String
  for at: U32
  U32

law bad.rd:
  for at: U32
  for r: Result<&1, &1, (U32 & String), JSON>
  U32

def bad.rd(at, r):
  match r:
    case Done{j}:
      0
    case Fail{(p, m)}:
      b2u(U32.is_eq(p, at))

def bad(s, at):
  bad.rd(at, JSON.read(s))

law chk_access:
  U32

law chk_access.rd:
  for r: Result<&1, &1, (U32 & String), JSON>
  U32

def chk_access.rd(r):
  match r:
    case Done{v}:
      access_score(v)
    case Fail{(p, m)}:
      0

def chk_access():
  chk_access.rd(JSON.read("{\"nums\": [10, 20, 30], \"name\": \"bend\"}"))

law access_score:
  for v: JSON
  U32

def access_score(v):
  n1 = Mb.default(&1, JSON, JSON.null(), LL.get(&1, JSON, 1n, JSON.items(JSON.get("nums", v))))
  a = b2u(U32.is_eq(JSON.as_u32(n1), 20))
  b = b2u(String.eq(JSON.as_string(JSON.get("name", v)), "bend"))
  c = b2u(nat_eq(LL.length(&1, JSON, JSON.items(JSON.get("nums", v))), 3n))
  d = b2u(U32.is_eq(JSON.as_u32(JSON.get("missing", v)), 0))
  (a + b + c + d : U32)

law main:
  U32

def main():
  a = rt(" {\"a\" : [1, -2, \"x\\ny\", true, null], \"b\":{}, \"c\":[]} ", "{\"a\":[1,-2,\"x\\ny\",true,null],\"b\":{},\"c\":[]}")
  b = bad("[1,", 3)
  c = bad("", 0)
  d = chk_access()
  (a * 1000 + b * 100 + c * 10 + d : U32)

#|Error:
#|- expected : a defined name
#|- observed : JSON
#|Context:
#|- out : String
#|Location: rt.rd
#|78 |   for out: String
#|79>|   for r: Result<&1, &1, (U32 & String), JSON>
#|80 |   U32
#|exit 1
