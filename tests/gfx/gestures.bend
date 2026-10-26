# gfx (gfx_gestures): Gesture.step reads scripted frames (a time and its
# events): a tap, a second tap near and soon after it, a press held past
# 500 ms (no tap when let go), a drag past its 8 pixel slop (dropped, and
# another lost), two fingers
# pinched out to twice their distance then turned a quarter clockwise, a
# press lost (no tap), a trackpad's Zoom and Swipe, three fingers spread
# and a two-finger tap (no tap). A pinch prints its scale and turn in
# hundredths.
import Base

def show(g: Gesture) -> String:
  match g:
    case Tap{x, y, c}:
      "tap " ++ F32.show(x) ++ " " ++ F32.show(y) ++ " " ++ U32.show(c)
    case LongPress{x, y}:
      "long " ++ F32.show(x) ++ " " ++ F32.show(y)
    case Drag{i, x, y, dx, dy}:
      "drag " ++ U32.show(i) ++ " " ++ F32.show(x) ++ " " ++ F32.show(y)
        ++ " " ++ F32.show(dx) ++ " " ++ F32.show(dy)
    case DragEnd{i, x, y, d}:
      "dragend " ++ U32.show(i) ++ " " ++ F32.show(x) ++ " " ++ F32.show(y)
        ++ " " ++ Bool.show(d)
    case Pan{x, y, dx, dy, f}:
      "pan " ++ F32.show(x) ++ " " ++ F32.show(y) ++ " " ++ F32.show(dx)
        ++ " " ++ F32.show(dy) ++ " " ++ U32.show(f)
    case Pinch{x, y, s, t, f}:
      "pinch " ++ F32.show(x) ++ " " ++ F32.show(y) ++ " "
        ++ F32.show(F32.round((s * 100.0 : F32))) ++ " "
        ++ F32.show(F32.round((t * 100.0 : F32))) ++ " " ++ U32.show(f)

def shows(gs: List<&2, Gesture>) -> IO(Unit):
  match gs:
    case Nil{}:
      IO.pure(Unit, Unit{})
    case g <> rest:
      do IO<Unit>:
        IO.print(show(g))
        shows(rest)

def frame(f: Nat & List<Event>, s: Gesture.State) ->
  Gesture.State & List<&2, Gesture>:
  (now, events) = f
  Gesture.step(events, s, now)

def shown(r: Gesture.State & List<&2, Gesture>, k: Gesture.State -> IO(Unit))
  -> IO(Unit):
  (s, gs) = r
  do IO<Unit>:
    shows(gs)
    k(s)

def play(frames: List<(Nat & List<Event>)>, s: Gesture.State) -> IO(Unit):
  match frames:
    case Nil{}:
      IO.pure(Unit, Unit{})
    case f <> rest:
      shown(frame(f, s), u => play(rest, u))

def down(id: U32, x: F32, y: F32) -> Event:
  Press{id, Finger{0.5, 1.0, 1.0}, x, y, 0, True{}}

def up(id: U32, x: F32, y: F32) -> Event:
  Press{id, Finger{0.5, 1.0, 1.0}, x, y, 0, False{}}

def go(id: U32, x: F32, y: F32) -> Event:
  Move{id, Finger{0.5, 1.0, 1.0}, x, y}

def main() -> IO(Unit):
  play([(1000n, [down(0, 10.0, 10.0)]), (1100n, [up(0, 10.0, 10.0)]),
    (1200n, [down(0, 12.0, 11.0), up(0, 12.0, 11.0)]),
    (2000n, [down(0, 40.0, 40.0)]), (2600n, []), (2700n, [up(0, 40.0, 40.0)]),
    (3000n, [down(0, 50.0, 50.0), go(0, 52.0, 50.0), go(0, 70.0, 50.0)]),
    (3050n, [go(0, 80.0, 55.0), up(0, 80.0, 55.0)]),
    (4000n, [down(1, 100.0, 100.0), down(2, 200.0, 100.0),
      go(2, 300.0, 100.0)]),
    (4050n, [go(2, 100.0, 300.0), up(1, 100.0, 100.0), up(2, 100.0, 300.0)]),
    (5000n, [down(3, 5.0, 5.0), Lost{3}, up(3, 5.0, 5.0),
      Zoom{1.0, 2.0, 1.25, F32.neg(0.5), 2}, Swipe{1.0, 2.0, 3.0, 4.0, 3}]),
    (6000n, [down(4, 0.0, 0.0), down(5, 60.0, 0.0), down(6, 0.0, 60.0)]),
    (6050n, [go(5, 120.0, 0.0), up(4, 0.0, 0.0), up(5, 120.0, 0.0),
      up(6, 0.0, 60.0)]),
    (7000n, [down(7, 10.0, 10.0), down(8, 30.0, 10.0)]),
    (7050n, [up(7, 10.0, 10.0), up(8, 30.0, 10.0)]),
    (8000n, [down(9, 0.0, 0.0), go(9, 20.0, 0.0), Lost{9}])], Gesture.new())

#|tap 10 10 1
#|tap 12 11 2
#|long 40 40
#|drag 0 70 50 18 0
#|drag 0 80 55 10 5
#|dragend 0 80 55 True
#|pan 200 100 50 0 2
#|pinch 200 100 200 0 2
#|pan 100 200 -100 100 2
#|pinch 100 200 100 157 2
#|pinch 1 2 125 -50 2
#|pan 1 2 3 4 3
#|pan 40 20 20 0 3
#|pinch 40 20 156 7 3
#|drag 9 20 0 20 0
#|dragend 9 20 0 False
