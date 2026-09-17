# Map keys that prefix each other ("a", "ab": the presence bit at pos
# 33 splits them) list in key order, Map.union takes the right map's
# value, and String.cmp puts the shorter string first
import Base

def kvs(xs: List<&2, Sigma<&2, &2, String, _ => U32>>) -> String:
  match xs:
    case Nil{}:
      "."
    case (k, v) <> t:
      k ++ "=" ++ U32.show(v) ++ "," ++ kvs(t)

def cs(r: (String & String) & Cmp) -> String:
  ((a, b), c) = r
  match c:
    case LT{}:
      "LT"
    case EQ{}:
      "EQ"
    case GT{}:
      "GT"

def main() -> IO(Unit):
  +m1 = Map.set(&2, U32, Map.set(&2, U32,
    Map.set(&2, U32, Map.new(&2, U32), "ab", 1), "a", 2), "b", 3)
  +m2 = Map.set(&2, U32, Map.set(&2, U32, Map.new(&2, U32), "a", 20), "c", 30)
  do IO<Unit>:
    Unit <- IO.print(kvs(Map.to_list(&2, U32, m1)))
    Unit <- IO.print(kvs(Map.to_list(&2, U32, Map.union(&2, U32, m1, m2))))
    Unit <- IO.print(kvs(Map.to_list(&2, U32, Map.union(&2, U32, m2, m1))))
    IO.print(cs(String.cmp("ab", "abc")) ++ cs(String.cmp("b", "abc"))
      ++ cs(String.cmp("", "a")))

#|a=2,ab=1,b=3,.
#|a=20,ab=1,b=3,c=30,.
#|a=2,ab=1,b=3,c=30,.
#|LTGTLT
