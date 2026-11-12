import Base

def value(r: Map<&2, U32> & U32) -> U32:
  (m, v) = r
  v

def has(r: Map<&2, U32> & Bool, stored: String) -> String:
  (m, found) = r
  Bool.show(found) ++ "/" ++ U32.show(value(Map.get(U32, 99, m, stored)))

def get(r: Map<&2, U32> & U32, stored: String) -> String:
  (m, got) = r
  U32.show(got) ++ "/" ++ U32.show(value(Map.get(U32, 99, m, stored)))

def pop(r: Map<&2, U32> & Maybe<&2, U32>) -> String:
  (m, v) = r
  U32.show(Maybe.default(&2, U32, v, 99)) ++ "/" ++ Nat.show(Map.size(&2, U32, m))

def result(+stored: String, +query: String) -> String:
  +m = Map.set(&2, U32, Map.new(&2, U32), stored, 37)
  String.join([has(Map.has(&2, U32, m, query), stored),
    get(Map.get(U32, 99, m, query), stored), pop(Map.pop(&2, U32, m, query))], "/")

def apply(r: Map<&1, (U32 -> U32)> & Maybe<&1, (U32 -> U32)>) -> U32:
  (m, f) = r
  match f:
    case None{}:
      0
    case Some{f}:
      f(41)

def affine.pop(r: Map<&1, (U32 -> U32)> & Maybe<&1, (U32 -> U32)>) -> U32:
  (m, missed) = r
  apply(Map.pop(&1, (U32 -> U32), m, "owned"))

def affine.has(r: Map<&1, (U32 -> U32)> & Bool) -> U32:
  (m, found) = r
  affine.pop(Map.pop(&1, (U32 -> U32), m, "owner"))

def affine(m: Map<&1, (U32 -> U32)>) -> U32:
  affine.has(Map.has(&1, (U32 -> U32), m, "owned"))

def has_mismatch(-t: String, -p: String) ->
  {Pair.snd(Map<&2, U32>, Bool, Map.has(&2, U32, MLeaf{SCon{'a', t}, 37}, SCon{'b', p})) == False{} : Bool}:
  {==}

def get_mismatch(-t: String, -p: String) ->
  {Pair.snd(Map<&2, U32>, U32, Map.get(U32, 99, MLeaf{SCon{'a', t}, 37}, SCon{'b', p})) == 99 : U32}:
  {==}

def pop_mismatch(-t: String, -p: String) ->
  {Pair.snd(Map<&2, U32>, Maybe<&2, U32>, Map.pop(&2, U32, MLeaf{SCon{'a', t}, 37}, SCon{'b', p})) == None{} : Maybe<&2, U32>}:
  {==}

def lane.pop(r: Map<&2, U32> & Maybe<&2, U32>) -> U32:
  (m, v) = r
  Maybe.default(&2, U32, v, 0)

def lane.has(r: Map<&2, U32> & Bool, +k: String) -> U32:
  (m, found) = r
  +m2 = m
  U32.add(Bool.to_u32(found), U32.add(value(Map.get(U32, 0, m2, k)),
    lane.pop(Map.pop(&2, U32, m2, k))))

def lane() -> U32:
  +k = String.repeat("x", 64n)
  lane.has(Map.has(&2, U32, MLeaf{k, 37}, k), k)

def tree(+d: Nat) -> U32:
  match d:
    case 0n:
      lane()
    case 1n+p:
      a b = tree(p) tree(p)
      U32.add(a, b)

def main() -> IO(Unit):
  +prefix = String.repeat("x", 128n)
  do IO<Unit>:
    IO.print(result("", ""))
    IO.print(result("a", "a"))
    IO.print(result("a", "b"))
    IO.print(result("ab", "a"))
    IO.print(result("a", "ab"))
    IO.print(result(prefix ++ "a", prefix ++ "a"))
    IO.print(result(prefix ++ "a", prefix ++ "b"))
    IO.print(result("\u{0}", ""))
    IO.print(result("\u{ffffffff}", "\u{ffffffff}"))
    IO.print(result("\u{ffffffff}", "\u{7fffffff}"))
    IO.print(result("\u{80000000}", "\u{0}"))
    IO.print(result("é", "é"))
    IO.print(U32.show(affine(Map.set(&1, (U32 -> U32),
      Map.new(&1, (U32 -> U32)), "owned", x => U32.inc(x)))))
    IO.print(U32.show(tree!(3n)))

#|True/37/37/37/37/0
#|True/37/37/37/37/0
#|False/37/99/37/99/1
#|False/37/99/37/99/1
#|False/37/99/37/99/1
#|True/37/37/37/37/0
#|False/37/99/37/99/1
#|False/37/99/37/99/1
#|True/37/37/37/37/0
#|False/37/99/37/99/1
#|False/37/99/37/99/1
#|False/37/99/37/99/1
#|42
#|600
