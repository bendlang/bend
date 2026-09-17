# Triangle: one orange triangle on a teal field; a click inside it adds
# a white square to the tally along the top edge; Esc or Close quits.
# A frame is an Image quadtree: flat tells whether a cell is one color
# (all four corners inside, or all beyond one edge) and draw emits one
# Pix the moment it is.
#
#   bend demos/app_triangle_2d/main.bend -o triangle && ./triangle
import Base

def Tri.pick(c: Bool, a: U32, b: U32) -> U32:
  match c:
    case True{}:
      a
    case False{}:
      b

def Tri.side(+ax: U32, +ay: U32, bx: U32, by: U32, px: U32, py: U32) -> Bool:
  ((bx - ax) * (py - ay) - (by - ay) * (px - ax) > 2147483647 : U32)

def Tri.inside(+x: U32, +y: U32) -> Bool:
  (Tri.side(256, 64, 64, 448, x, y) && Tri.side(64, 448, 448, 448, x, y)
    && Tri.side(448, 448, 256, 64, x, y))

def Tri.out(
  +ax: U32, +ay: U32, +bx: U32, +by: U32, +x0: U32, +y0: U32, +x1: U32,
  +y1: U32
) -> Bool:
  Bool.not((Tri.side(ax, ay, bx, by, x0, y0) || Tri.side(ax, ay, bx, by, x1, y0)
    || Tri.side(ax, ay, bx, by, x0, y1) || Tri.side(ax, ay, bx, by, x1, y1)))

def Tri.color(+x: U32, +y: U32, n: U32) -> U32:
  Tri.pick(Tri.inside(x, y), 16744499,
    Tri.pick(((y < 8) && (x < 16 * n) && U32.is_eq((x .&. 8 : U32), 0) : U32),
      16777215, 3362125))

def Tri.flat(d: Nat, +x0: U32, +y0: U32, n: U32) -> Bool:
  +s = U32.shln(1, d)
  +x1 = (x0 + s : U32)
  +y1 = (y0 + s : U32)
  +strip = ((y0 < 8) && (x0 < 16 * n) : U32)
  (strip && (s <= 8 : U32)) || (Bool.not(strip)
    && ((Tri.inside(x0, y0) && Tri.inside(x1, y0) && Tri.inside(x0, y1)
        && Tri.inside(x1, y1))
      || Tri.out(256, 64, 64, 448, x0, y0, x1, y1)
      || Tri.out(64, 448, 448, 448, x0, y0, x1, y1)
      || Tri.out(448, 448, 256, 64, x0, y0, x1, y1)))

def Tri.draw(+d: Nat, flat: Bool, +x0: U32, +y0: U32, +n: U32) -> Image:
  match d:
    case 0n:
      Pix{Tri.color(x0, y0, n)}
    case 1n+e:
      match flat:
        case True{}:
          Pix{Tri.color(x0, y0, n)}
        case False{}:
          +h = U32.shln(1, e)
          +x1 = (x0 + h : U32)
          +y1 = (y0 + h : U32)
          tl tr bl br = Tri.draw(e, Tri.flat(e, x0, y0, n), x0, y0, n)
            Tri.draw(e, Tri.flat(e, x1, y0, n), x1, y0, n)
            Tri.draw(e, Tri.flat(e, x0, y1, n), x0, y1, n)
            Tri.draw(e, Tri.flat(e, x1, y1, n), x1, y1, n)
          Qua{tl, tr, bl, br}

def Tri.view(n: U32) -> U32 & Image:
  +m = n
  (m, Tri.draw(9n, Tri.flat(9n, 0, 0, m), 0, 0, m))

def Tri.event(e: Event, +n: U32) -> Maybe<U32>:
  match e:
    case Key{27, True{}}:
      None{}
    case Close{}:
      None{}
    case Mouse{x, y, button, True{}}:
      Some{Tri.pick(Tri.inside(x, y), (n + 1 : U32), n)}
    case _:
      Some{n}

def Tri.events(events: List<Event>, n: U32) -> Maybe<U32>:
  match events:
    case []:
      Some{n}
    case e <> rest:
      Maybe.bind(&1, U32, U32, Tri.event(e, n), m => Tri.events(rest, m))

def Tri.tick(events: List<Event>, n: U32) -> IO(Maybe<U32>):
  IO.pure(Maybe<U32>, Tri.events(events, n))

def main() -> IO(Unit):
  App.run(~U32, ~App{Tri.view, Tri.tick}, "Triangle", 512, 512, 0)
