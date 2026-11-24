import Base

def vals(a: Array<U32>) -> U32:
  List.foldl(~&1, ~U32, ~U32, ~(s => x => (s * 31 + x : U32)), Array.to_list(~U32, a), 0)

def texts(xs: List<String>) -> Nat:
  match xs:
    case []: 0n
    case h <> t: (String.length(h) + texts(t) : Nat)

def boxed(p: Array<String> & Array<String>) -> U32:
  (a, b) = p
  xs = Array.to_list(~String, a)
  ys = Array.to_list(~String, Array.set(String, b, 0, "changed"))
  U32.from_nat((texts(xs) + texts(ys) : Nat))

def fan(+d: Nat, +x: U32) -> U32:
  match d:
    case 0n:
      (vals(Array.set(U32, [x : U32*8n], 6, (x + 1 : U32))) + boxed(Array.fork(String, [U32.show(x) : String*4n])) : U32)
    case 1n+p:
      a b = fan(p, x) fan(p, (x + 1 : U32))
      (a + b : U32)

def main() -> U32:
  fan!(6n, 42)

#|2578033920
