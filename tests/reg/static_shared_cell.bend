# reg (reg_static_shared_cell): Array.new fills 2^d cells with one +value
# and wraps it in a redirect counted 2^d. With the value a static
# literal, the array's drop released that redirect to zero and handed
# the static node to term_drop, which threaded its stack through the
# node's first word and offered its cell to the heap: the next read of
# the literal faulted. term_drop now skips a static root, as its child
# walk already did; term_sink needs no guard of its own.
import Base

def sl(s: String, +acc: U32) -> U32:
  match s:
    case SNil{}:
      acc
    case SCon{h, t}:
      Chr{n} = h
      sl(t, (acc * 31 + n : U32))

def took(r: Array<String> & U32) -> U32:
  (a2, n) = r
  n

def fill(+k: Nat, +acc: U32) -> U32:
  match k:
    case 0n:
      acc
    case 1n+p:
      a = Array.new(String, 3n, "static")
      n = took(Array.size(String, a))
      fill(p, sl("static", (acc + n : U32)))

def main() -> IO(Unit):
  IO.print(U32.show(fill(4n, 0)))

#|651689688
