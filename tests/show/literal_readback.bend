# a value prints back as its literal on every lane: a list as [a, b], a
# tuple as (a, b, c) (its right-nested Tuples flattened, as the parser
# nests them), an array as its slots, a nested list of lists as such
import Base

def main() -> (List<U32> & (U32 & Nat & Char) & List<List<Bool>> & Array<U32> & List<U32>):
  (7 <> 7 <> [7], (1, 2n, 'c'), [[True{}], []], [3 : U32*2n], [])

#|([7, 7, 7], (1, 2n, 'c'), [[True{}], []], [3, 3], [])
