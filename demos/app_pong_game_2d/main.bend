# Pong: two paddles and a ball on a 512 x 512 field. W/S move the left
# paddle, Up/Down (63232, 63233) the right; Esc or Close quits. The ball
# flies 3 pixels per frame along two direction flags (right, down): a
# wall or a paddle flips one, a side resets it to the centre. A frame is
# an Image quadtree: flat tells whether a cell is one color and draw
# emits one Pix the moment it is.
#
#   bend demos/app_pong_game_2d/main.bend -o pong && ./pong
import Base

type Pong.Keys is Data:
  Keys{w: Bool, s: Bool, up: Bool, down: Bool}

type Pong is Data:
  Pong{w: U32, h: U32, ly: U32, ry: U32, keys: Pong.Keys, bx: U32, by: U32,
    dx: Bool, dy: Bool}

def Pong.init(+sw: U32, +sh: U32) -> Pong:
  +mid = U32.div(U32.sub(sh, 96), 2)
  +cx = U32.div(U32.sub(sw, 8), 2)
  +cy = U32.div(U32.sub(sh, 8), 2)
  Pong{sw, sh, mid, mid, Keys{False{}, False{}, False{}, False{}}, cx, cy,
    True{}, True{}}

def Pong.pick(c: Bool, a: U32, b: U32) -> U32:
  match c:
    case True{}:
      a
    case False{}:
      b

# Keys
# ----

def Pong.set(on: Bool, down: Bool, old: Bool) -> Bool:
  match on:
    case True{}:
      down
    case False{}:
      old

def Pong.press(+code: U32, +down: Bool, keys: Pong.Keys) -> Pong.Keys:
  Keys{w, s, up, dn} = keys
  Keys{Pong.set(U32.is_eq(code, 119), down, w),
    Pong.set(U32.is_eq(code, 115), down, s),
    Pong.set(U32.is_eq(code, 63232), down, up),
    Pong.set(U32.is_eq(code, 63233), down, dn)}

def Pong.event(e: Event, g: Pong) -> Maybe<Pong>:
  match e:
    case Key{27, True{}}:
      None{}
    case Key{code, down}:
      Pong{sw, sh, ly, ry, keys, bx, by, dx, dy} = g
      Some{Pong{sw, sh, ly, ry, Pong.press(code, down, keys), bx, by, dx, dy}}
    case Close{}:
      None{}
    case _:
      Some{g}

def Pong.events(events: List<Event>, g: Pong) -> Maybe<Pong>:
  match events:
    case []:
      Some{g}
    case e <> rest:
      Maybe.bind(&1, Pong, Pong, Pong.event(e, g), g2 => Pong.events(rest, g2))

# Motion
# ------

def Pong.paddle(+y: U32, up: Bool, down: Bool, +h: U32) -> U32:
  match up down:
    case True{} False{}:
      Pong.pick((y < 6 : U32), 0, (y - 6 : U32))
    case False{} True{}:
      Pong.pick((y > U32.sub(h, 96) : U32), U32.sub(h, 96), (y + 6 : U32))
    case _ _:
      y

def Pong.overlap(+by: U32, +py: U32) -> Bool:
  ((by + 8 >= py) && (by <= py + 96) : U32)

def Pong.reset(out: Bool, g: Pong) -> Pong:
  match out:
    case True{}:
      Pong{+sw, +sh, ly, ry, keys, bx, by, dx, dy} = g
      +cx = U32.div(U32.sub(sw, 8), 2)
      +cy = U32.div(U32.sub(sh, 8), 2)
      Pong{sw, sh, ly, ry, keys, cx, cy, True{}, True{}}
    case False{}:
      g

def Pong.step(+g: Pong) -> Pong:
  Pong{+sw, +sh, ly, ry, keys, bx, by, dx, dy} = g
  Keys{w, s, up, down} = keys
  +ly2 = Pong.paddle(ly, w, s, sh)
  +ry2 = Pong.paddle(ry, up, down, sh)
  +by2 = Pong.pick(dy, (by + 3 : U32), (by - 3 : U32))
  +wall = (by2 > U32.sub(sh, 8) : U32)
  +bx2 = Pong.pick(dx, (bx + 3 : U32), (bx - 3 : U32))
  +hit = (Bool.not(dx) && (bx2 <= 16) && Pong.overlap(by2, ly2)
    || dx && (bx2 + 8 >= U32.sub(sw, 16)) && Pong.overlap(by2, ry2) : U32)
  +bx3 = Pong.pick(hit, bx, bx2)
  Pong.reset((bx3 > U32.sub(sw, 8) : U32),
    Pong{sw, sh, ly2, ry2, keys, bx3, Pong.pick(wall, by, by2), Bool.xor(hit, dx),
      Bool.xor(wall, dy)})

def Pong.tick(events: List<Event>, g: Pong) -> IO(Maybe<Pong>):
  IO.pure(Maybe<Pong>, Maybe.bind(&1, Pong, Pong, Pong.events(events, g),
    g2 => Some{Pong.step(g2)}))

# Draw
# ----

def Pong.inside(
  +x0: U32, +y0: U32, +s: U32, +rx: U32, +ry: U32, rw: U32, rh: U32
) -> Bool:
  ((rx <= x0) && (x0 + s <= rx + rw) && (ry <= y0) && (y0 + s <= ry + rh) : U32)

def Pong.outside(
  +x0: U32, +y0: U32, +s: U32, +rx: U32, +ry: U32, rw: U32, rh: U32
) -> Bool:
  ((x0 + s <= rx) || (rx + rw <= x0) || (y0 + s <= ry) || (ry + rh <= y0) : U32)

def Pong.color(+x: U32, +y: U32, +g: Pong) -> U32:
  Pong{sw, sh, ly, ry, keys, bx, by, dx, dy} = g
  +rx = U32.sub(sw, 16)
  Pong.pick(Pong.inside(x, y, 1, bx, by, 8, 8), 16763904,
    Pong.pick(Pong.inside(x, y, 1, 8, ly, 8, 96)
      || Pong.inside(x, y, 1, rx, ry, 8, 96), 16777215, 0))

def Pong.flat(d: Nat, +x0: U32, +y0: U32, +g: Pong) -> Bool:
  Pong{sw, sh, ly, ry, keys, bx, by, dx, dy} = g
  +s = U32.shln(1, d)
  +rx = U32.sub(sw, 16)
  Pong.inside(x0, y0, s, bx, by, 8, 8) || Pong.outside(x0, y0, s, bx, by, 8, 8)
    && (Pong.inside(x0, y0, s, 8, ly, 8, 96)
      || Pong.inside(x0, y0, s, rx, ry, 8, 96)
      || Pong.outside(x0, y0, s, 8, ly, 8, 96)
        && Pong.outside(x0, y0, s, rx, ry, 8, 96))

def Pong.draw(+d: Nat, flat: Bool, +x0: U32, +y0: U32, +g: Pong) -> Image:
  match d:
    case 0n:
      Pix{Pong.color(x0, y0, g)}
    case 1n+e:
      match flat:
        case True{}:
          Pix{Pong.color(x0, y0, g)}
        case False{}:
          +h = U32.shln(1, e)
          +x1 = (x0 + h : U32)
          +y1 = (y0 + h : U32)
          tl tr bl br = Pong.draw(e, Pong.flat(e, x0, y0, g), x0, y0, g)
            Pong.draw(e, Pong.flat(e, x1, y0, g), x1, y0, g)
            Pong.draw(e, Pong.flat(e, x0, y1, g), x0, y1, g)
            Pong.draw(e, Pong.flat(e, x1, y1, g), x1, y1, g)
          Qua{tl, tr, bl, br}

def Pong.view(g: Pong) -> Pong & Image:
  Pong{+sw, +sh, ly, ry, keys, bx, by, dx, dy} = g
  +depth = U32.cover(Bool.pick(U32, U32.is_ge(sw, sh), sw, sh))
  +g2 = {Pong{sw, sh, ly, ry, keys, bx, by, dx, dy} : Pong}
  (g2, Pong.draw(depth, Pong.flat(depth, 0, 0, g2), 0, 0, g2))

def Pong.bootstrapped2(w: U32, h: U32, sized: Window & U32 & U32) -> IO(Unit):
  (pw, wh) = sized
  (w2, h2) = wh
  do IO<Unit>:
    u : Unit <- Window.close(pw)
    App.run(~Pong, ~App{Pong.view, Pong.tick}, "Pong", w, h, Pong.init(w2, h2))

def Pong.bootstrapped(sized: Window & U32 & U32) -> IO(Unit):
  (w1, wh1) = sized
  (w, h) = wh1
  do IO<Unit>:
    s2 : Window & U32 & U32 <- Window.size(w1)
    Pong.bootstrapped2(w, h, s2)

def main() -> IO(Unit):
  do IO<Unit>:
    probe : Window <- IO.try(Window, Window.open("Pong", 512, 512))
    s : Window & U32 & U32 <- Window.size(probe)
    Pong.bootstrapped(s)
