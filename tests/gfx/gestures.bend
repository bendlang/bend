# gfx (gfx_gestures): Gesture.step reads scripted frames (a time and its
# events): a tap, a second tap near and soon after it, a press held past
# 500 ms drifting 5 pixels (a LongPress where it is, no tap when let go), a
# drag past its 8 pixel slop (dropped, and
# another lost), two fingers
# pinched out to twice their distance then turned a quarter clockwise, a
# press lost (no tap), a trackpad's Zoom and Swipe, three fingers spread,
# a two-finger tap (no tap), a pinch's last finger moved 1 pixel (no drag)
# then past 8, a held press's jitter (no drag) then a drag, a press up far
# with no Move (a drag) then a tap where it went up, in frames 700 ms apart
# a press up at 100 ms (a tap) and one at 650 (a LongPress), and a second
# finger ending a drag (lost). A pinch prints its scale and turn in
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

def down(id: U32, x: F32, y: F32, t: U32) -> Event:
  Press{id, Finger{0.5, 1.0, 1.0}, x, y, t, 0, True{}}

def up(id: U32, x: F32, y: F32, t: U32) -> Event:
  Press{id, Finger{0.5, 1.0, 1.0}, x, y, t, 0, False{}}

def go(id: U32, x: F32, y: F32, t: U32) -> Event:
  Move{id, Finger{0.5, 1.0, 1.0}, x, y, t}

def main() -> IO(Unit):
  play([(1000n, [down(0, 10.0, 10.0, 1000)]),
    (1100n, [up(0, 10.0, 10.0, 1100)]),
    (1200n, [down(0, 12.0, 11.0, 1200), up(0, 12.0, 11.0, 1200)]),
    (2000n, [down(0, 40.0, 40.0, 2000)]), (2600n, [go(0, 43.0, 44.0, 2600)]),
    (2700n, [up(0, 40.0, 40.0, 2700)]),
    (3000n, [down(0, 50.0, 50.0, 3000), go(0, 52.0, 50.0, 3000),
      go(0, 70.0, 50.0, 3000)]),
    (3050n, [go(0, 80.0, 55.0, 3050), up(0, 80.0, 55.0, 3050)]),
    (4000n, [down(1, 100.0, 100.0, 4000), down(2, 200.0, 100.0, 4000),
      go(2, 300.0, 100.0, 4000)]),
    (4050n, [go(2, 100.0, 300.0, 4050), up(1, 100.0, 100.0, 4050),
      up(2, 100.0, 300.0, 4050)]),
    (5000n, [down(3, 5.0, 5.0, 5000), Lost{3}, up(3, 5.0, 5.0, 5000),
      Zoom{1.0, 2.0, 1.25, F32.neg(0.5), 2}, Swipe{1.0, 2.0, 3.0, 4.0, 3}]),
    (6000n, [down(4, 0.0, 0.0, 6000), down(5, 60.0, 0.0, 6000),
      down(6, 0.0, 60.0, 6000)]),
    (6050n, [go(5, 120.0, 0.0, 6050), up(4, 0.0, 0.0, 6050),
      up(5, 120.0, 0.0, 6050), up(6, 0.0, 60.0, 6050)]),
    (7000n, [down(7, 10.0, 10.0, 7000), down(8, 30.0, 10.0, 7000)]),
    (7050n, [up(7, 10.0, 10.0, 7050), up(8, 30.0, 10.0, 7050)]),
    (8000n, [down(9, 0.0, 0.0, 8000), go(9, 20.0, 0.0, 8000), Lost{9}]),
    (9000n, [down(10, 100.0, 100.0, 9000), down(11, 200.0, 100.0, 9000)]),
    (9050n, [up(10, 100.0, 100.0, 9050), go(11, 201.0, 100.0, 9050),
      go(11, 215.0, 100.0, 9050), up(11, 215.0, 100.0, 9050)]),
    (10000n, [down(12, 10.0, 10.0, 10000)]), (10600n, []),
    (10650n, [go(12, 10.5, 10.0, 10650), go(12, 30.0, 10.0, 10650),
      up(12, 30.0, 10.0, 10650)]),
    (11000n, [down(13, 10.0, 10.0, 11000)]),
    (11100n, [up(13, 300.0, 300.0, 11100), down(14, 50.0, 50.0, 11100),
      up(14, 54.0, 53.0, 11150)]),
    (12000n, [down(15, 70.0, 70.0, 12000)]),
    (12700n, [up(15, 70.0, 70.0, 12100), down(16, 90.0, 90.0, 12700)]),
    (13400n, [up(16, 90.0, 90.0, 13350)]),
    (14000n, [down(17, 0.0, 0.0, 14000), go(17, 20.0, 0.0, 14000),
      down(18, 100.0, 0.0, 14000), go(18, 120.0, 0.0, 14000),
      up(17, 20.0, 0.0, 14000), up(18, 120.0, 0.0, 14000)])], Gesture.new())

#|tap 10 10 1
#|tap 12 11 2
#|long 43 44
#|drag 0 70 50 18 0
#|drag 0 80 55 10 5
#|dragend 0 80 55 False
#|pan 200 100 50 0 2
#|pinch 200 100 200 0 2
#|pan 100 200 -100 100 2
#|pinch 100 200 100 157 2
#|pinch 1 2 125 -50 2
#|pan 1 2 3 4 3
#|pan 40 20 20 0 3
#|pinch 40 20 156 7 3
#|drag 9 20 0 20 0
#|dragend 9 20 0 True
#|drag 11 215 100 14 0
#|dragend 11 215 100 False
#|long 10 10
#|drag 12 30 10 19.5 0
#|dragend 12 30 10 False
#|drag 13 300 300 290 290
#|dragend 13 300 300 False
#|tap 54 53 1
#|tap 70 70 1
#|long 90 90
#|drag 17 20 0 20 0
#|dragend 17 20 0 True
#|pan 70 0 10 0 2
#|pinch 70 0 125 0 2
