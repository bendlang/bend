# Array.get_unchecked on a two-word element: the index is shifted by the
# element's width, so the last cell and a middle one read their own words
import Base

type Pt is Data:
  MkPt{x: U32, y: U32}

def mk() -> Array<Pt>:
  Array.set(Pt, Array.set(Pt, Array.set(Pt,
    Array.set(Pt, [MkPt{0, 0} : Pt*4n], 0, MkPt{1, 2}), 1, MkPt{3, 4}),
    2, MkPt{5, 6}), 3, MkPt{7, 8})

def pt(p: Pt) -> U32:
  match p:
    case MkPt{x, y}:
      U32.add(U32.mul(x, 10), y)

def then(r: Array<Pt> & Pt, k: Array<Pt> -> U32 -> U32) -> U32:
  match r:
    case Tuple{a, p}:
      k(a, pt(p))

@unsafe
def main() -> IO(Unit):
  IO.print(U32.show(
    then(Array.get_unchecked(Pt, mk(), 3), a => x =>
      then(Array.get_unchecked(Pt, a, 1), b => y =>
        then(Array.get(Pt, b, 2), c => z =>
          U32.add(U32.mul(U32.add(U32.mul(x, 100), y), 100), z))))))

#|783456
