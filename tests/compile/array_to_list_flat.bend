import Base

type Shape is Data:
  Z{}
  W{x: U32, y: U32}
  S{text: String}

def shape(x: Shape) -> String:
  match x:
    case Z{}: "z"
    case W{x, y}: U32.show(x) ++ ":" ++ U32.show(y)
    case S{text}: text

def shapes(xs: List<Shape>) -> String:
  match xs:
    case []:
      ""
    case h <> t:
      shape(h) ++ "/" ++ shapes(t)

def nums(xs: List<U32>, +s: U32) -> U32:
  match xs:
    case []: s
    case h <> t: nums(t, (s * 10 + h : U32))

def funcs(xs: List<(U32 -> U32)>, +s: U32) -> U32:
  match xs:
    case []: s
    case h <> t: funcs(t, (s * 10 + h(3) : U32))

def box(n: U32) -> Array<(U32 -> U32)>:
  ALeaf{x => (n + x : U32)}

def shared(p: Array<Shape> & Array<Shape>) -> String:
  (a, b) = p
  xs = Array.to_list(~Shape, a)
  ys = Array.to_list(~Shape, Array.set(Shape, b, 0, S{"changed"}))
  shapes(xs) ++ "|" ++ shapes(ys)

def run(+n: U32) -> IO(Unit):
  a = Array.set(Shape, Array.set(Shape, [Z{} : Shape*4n], 1, W{n, 2}), 2, S{U32.show(n)})
  f = Array.to_list(~(U32 -> U32))
  do IO<Unit>:
    Unit <- IO.print(U32.show(nums(Array.to_list(~U32, Array.set(U32, [n : U32*4n], 2, 3)), 0)))
    Unit <- IO.print(U32.show(funcs(f(ANode{box(n), box(2)}), 0)))
    Unit <- IO.print(shared(Array.fork(Shape, a)))
    Unit <- IO.print(shapes(Array.to_list.go(~Shape, ALeaf{S{U32.show(n)}}, [S{"tail"}])))
    IO.print(Nat.show(List.length(&1, Unit, Array.to_list(~Unit, [Unit{} : Unit*4n]))))

def main() -> IO(Unit):
  run(4)

#|4434
#|75
#|z/4:2/4/z/|changed/4:2/4/z/
#|4/tail/
#|4
