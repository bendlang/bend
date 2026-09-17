# [x : T*n] is Array.new(T, log2(n), x): an n-slot array of x, n a
# literal power of two; [x : T^d] takes the depth d; the ": T" names the
# operators inside x, as the parens' ": T" does; an array prints its slots
import Base

def main() -> (Array<U32> & Array<Bool>):
  ([1 + 2 : U32*4n], [True{} : Bool^1n])

#|([3, 3, 3, 3], [True{}, True{}])
