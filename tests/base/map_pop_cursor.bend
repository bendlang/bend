import Base

def value(r: Map<&2, U32> & U32) -> U32:
  (m, v) = r
  v

def result(r: Map<&2, U32> & Maybe<&2, U32>, other: String) -> String:
  (m, v) = r
  U32.show(Maybe.default(&2, U32, v, 99)) ++ "/" ++
    U32.show(value(Map.get(U32, 0, m, other)))

def sample(+prefix: String) -> Map<&2, U32>:
  m0 = Map.new(&2, U32)
  m1 = Map.set(&2, U32, m0, prefix ++ "a", 1)
  m2 = Map.set(&2, U32, m1, prefix ++ "ab", 2)
  m3 = Map.set(&2, U32, m2, prefix ++ "b", 3)
  Map.set(&2, U32, m3, prefix ++ "ba", 4)

def main() -> IO(Unit):
  +p = String.repeat("x😀", 64n)
  +m = sample(p)
  +raw = {MNode{33n, MTip{}, MNode{0n, MLeaf{"", 1}, MLeaf{"ab", 7}}} : Map<&2, U32>}
  do IO<Unit>:
    IO.print(result(Map.pop(&2, U32, m, p ++ "ab"), p ++ "a"))
    IO.print(result(Map.pop(&2, U32, m, p ++ "ba"), p ++ "b"))
    IO.print(result(Map.pop(&2, U32, m, p ++ "bax"), p ++ "ba"))
    IO.print(result(Map.pop(&2, U32, m, ""), p ++ "ab"))
    IO.print(result(Map.pop(&2, U32, raw, "ab"), ""))

#|2/1
#|4/3
#|99/4
#|99/2
#|7/0
