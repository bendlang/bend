# Triangle: one orange triangle on a teal field; a click inside it adds
# a white square to the tally along the top edge; Esc or Close quits.
# A frame is an Image quadtree: flat tells whether a cell is one color
# (all four corners inside, or all beyond one edge) and draw emits one
# Pix the moment it is. Geometry derives from the window size.
#
#   bend demos/app_triangle_2d/main.bend -o triangle && ./triangle
import Base

type Tri is Data:
  Tri{n: U32, w: U32, h: U32}

type Tri.Geo is Data:
  Geo{ax: U32, ay: U32, bx: U32, by: U32, cx: U32, cy: U32}

def Tri.pick(c: Bool, a: U32, b: U32) -> U32:
  match c:
    case True{}:
      a
    case False{}:
      b

def Tri.geo(+w: U32, +h: U32) -> Tri.Geo:
  Geo{U32.div(w, 2), U32.div(h, 8), U32.div(w, 8), U32.div(U32.mul(h, 7), 8),
    U32.div(U32.mul(w, 7), 8), U32.div(U32.mul(h, 7), 8)}

def Tri.side(+ax: U32, +ay: U32, bx: U32, by: U32, px: U32, py: U32) -> Bool:
  ((bx - ax) * (py - ay) - (by - ay) * (px - ax) > 2147483647 : U32)

def Tri.inside(+x: U32, +y: U32, +geo: Tri.Geo) -> Bool:
  Geo{ax, ay, bx, by, cx, cy} = geo
  (Tri.side(ax, ay, bx, by, x, y) && Tri.side(bx, by, cx, cy, x, y)
    && Tri.side(cx, cy, ax, ay, x, y))

def Tri.out(
  +ax: U32, +ay: U32, +bx: U32, +by: U32, +x0: U32, +y0: U32, +x1: U32,
  +y1: U32
) -> Bool:
  Bool.not((Tri.side(ax, ay, bx, by, x0, y0) || Tri.side(ax, ay, bx, by, x1, y0)
    || Tri.side(ax, ay, bx, by, x0, y1) || Tri.side(ax, ay, bx, by, x1, y1)))

def Tri.color(+x: U32, +y: U32, n: U32, +geo: Tri.Geo) -> U32:
  Geo{ax, ay, bx, by, cx, cy} = geo
  +ix = Tri.inside(x, y, geo)
  Tri.pick(ix, 16744499,
    Tri.pick(((y < 8) && (x < 16 * n) && U32.is_eq((x .&. 8 : U32), 0) : U32),
      16777215, 3362125))

def Tri.flat(d: Nat, +x0: U32, +y0: U32, n: U32, +geo: Tri.Geo) -> Bool:
  Geo{ax, ay, bx, by, cx, cy} = geo
  +s = U32.shln(1, d)
  +x1 = (x0 + s : U32)
  +y1 = (y0 + s : U32)
  +strip = ((y0 < 8) && (x0 < 16 * n) : U32)
  (strip && (s <= 8 : U32)) || (Bool.not(strip)
    && ((Tri.inside(x0, y0, geo) && Tri.inside(x1, y0, geo) && Tri.inside(x0, y1, geo)
        && Tri.inside(x1, y1, geo))
      || Tri.out(ax, ay, bx, by, x0, y0, x1, y1)
      || Tri.out(bx, by, cx, cy, x0, y0, x1, y1)
      || Tri.out(cx, cy, ax, ay, x0, y0, x1, y1)))

def Tri.draw(+d: Nat, flat: Bool, +x0: U32, +y0: U32, +n: U32, +geo: Tri.Geo) -> Image:
  match d:
    case 0n:
      Pix{Tri.color(x0, y0, n, geo)}
    case 1n+e:
      match flat:
        case True{}:
          Pix{Tri.color(x0, y0, n, geo)}
        case False{}:
          +h = U32.shln(1, e)
          +x1 = (x0 + h : U32)
          +y1 = (y0 + h : U32)
          tl tr bl br = Tri.draw(e, Tri.flat(e, x0, y0, n, geo), x0, y0, n, geo)
            Tri.draw(e, Tri.flat(e, x1, y0, n, geo), x1, y0, n, geo)
            Tri.draw(e, Tri.flat(e, x0, y1, n, geo), x0, y1, n, geo)
            Tri.draw(e, Tri.flat(e, x1, y1, n, geo), x1, y1, n, geo)
          Qua{tl, tr, bl, br}

def Tri.view(t: Tri) -> Tri & Image:
  Tri{n, +w, +h} = t
  +depth = U32.cover(Bool.pick(U32, U32.is_ge(w, h), w, h))
  +geo = Tri.geo(w, h)
  +m = n
  +t2 = {Tri{m, w, h} : Tri}
  (t2, Tri.draw(depth, Tri.flat(depth, 0, 0, m, geo), 0, 0, m, geo))

def Tri.event(e: Event, t: Tri) -> Maybe<Tri>:
  match e:
    case Key{27, True{}}:
      None{}
    case Close{}:
      None{}
    case Mouse{x, y, button, True{}}:
      Tri{n, +w, +h} = t
      +geo = Tri.geo(w, h)
      +m = n
      Some{Tri{Tri.pick(Tri.inside(x, y, geo), (m + 1 : U32), m), w, h}}
    case _:
      Some{t}

def Tri.events(events: List<Event>, t: Tri) -> Maybe<Tri>:
  match events:
    case []:
      Some{t}
    case e <> rest:
      Maybe.bind(&1, Tri, Tri, Tri.event(e, t), t2 => Tri.events(rest, t2))

def Tri.tick(events: List<Event>, t: Tri) -> IO(Maybe<Tri>):
  IO.pure(Maybe<Tri>, Tri.events(events, t))

def Tri.sized2(w: U32, h: U32, sized: Window & U32 & U32) -> IO(Unit):
  (pw, wh) = sized
  (w2, h2) = wh
  do IO<Unit>:
    u : Unit <- Window.close(pw)
    App.run(~Tri, ~App{Tri.view, Tri.tick}, "Triangle", w, h, Tri{0, w2, h2})

def Tri.sized(sized: Window & U32 & U32) -> IO(Unit):
  (pw, wh) = sized
  (w, h) = wh
  do IO<Unit>:
    s2 : Window & U32 & U32 <- Window.size(pw)
    Tri.sized2(w, h, s2)

def main() -> IO(Unit):
  do IO<Unit>:
    probe : Window <- IO.try(Window, Window.open("Triangle", 512, 512))
    s : Window & U32 & U32 <- Window.size(probe)
    Tri.sized(s)
