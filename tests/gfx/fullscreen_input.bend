# gfx (gfx_fullscreen_input): fullscreen input through window.c's own
# handlers. fake (fullscreen_input.c) shows the 64 x 48 image at 4x in a
# 256 x 256 window, bars 32 tall, and feeds a mouse (and on X11 a touch
# screen and a pen): positions and a finger's size come in the image's units,
# a pointer with no button held leaves on a bar once and its press there is
# dropped, and a grabbed motion is a Look in the image's units. True once those lines come,
# in order, from the first frame. Without a display, True, as window_title.
import Base

def fake(window: Window) -> IO(Window & String):
  import "./fullscreen_input.c"
  import "./fullscreen_input.js"

def tool(t: Tool) -> String:
  match t:
    case Tool.Mouse{}:
      "mouse"
    case Tool.Finger{force, width, height}:
      "finger " ++ F32.show(width) ++ " " ++ F32.show(height)
    case Tool.Pen{force, tangential, tilt_x, tilt_y, twist}:
      "pen"

def mine(+time: U32, s: String) -> String:
  Bool.pick(String, U32.is_ge(time, 4000000000),
    s ++ " " ++ U32.show(time) ++ "\n", "")

# An event's line: a Press or Move only if the test made it.
def line(e: Event) -> String:
  match e:
    case Press{id, t, x, y, +time, button, down}:
      mine(time, "press " ++ U32.show(id) ++ " " ++ tool(t) ++ " "
        ++ F32.show(x) ++ " " ++ F32.show(y) ++ " " ++ U32.show(button) ++ " "
        ++ Bool.show(down))
    case Move{id, t, x, y, +time}:
      mine(time, "move " ++ U32.show(id) ++ " " ++ tool(t) ++ " "
        ++ F32.show(x) ++ " " ++ F32.show(y))
    case Leave{id}:
      "leave " ++ U32.show(id) ++ "\n"
    case Look{dx, dy}:
      "look " ++ F32.show(dx) ++ " " ++ F32.show(dy) ++ "\n"
    case _:
      ""

def lines(events: List<Event>, got: String) -> String:
  match events:
    case Nil{}:
      got
    case e <> rest:
      lines(rest, got ++ line(e))

def want(platform: String) -> String:
  Bool.pick(String, String.eq(platform, "mac"),
    "move 0 mouse 32 32 4000000001\n"
      ++ "leave 0\n"
      ++ "move 0 mouse 16 16 4000000004\n"
      ++ "press 0 mouse 16 16 0 True 4000000005\n"
      ++ "press 0 mouse 16 -5.5 0 False 4000000006\n"
      ++ "leave 0\n"
      ++ "look 10 -5\n",
    "move 0 mouse 32 32 4000000001\n"
      ++ "leave 0\n"
      ++ "move 0 mouse 16 16 4000000004\n"
      ++ "press 0 mouse 16 16 0 True 4000000005\n"
      ++ "press 0 mouse 16 -5.5 0 False 4000000006\n"
      ++ "press 1 finger 0.25 0.25 32 32 0 True 4000000008\n"
      ++ "press 1 finger 0.25 0.25 32 32 0 False 4000000009\n"
      ++ "move 1 pen 32 32 4000000010\n"
      ++ "leave 1\n"
      ++ "look 10 -5\n")

def report(window: Window, text: String) -> IO(Unit):
  do IO<Unit>:
    Window.close(window)
    IO.print(text)

def verdict(ok: Bool, window: Window, got: String) -> IO(Unit):
  match ok:
    case True{}:
      report(window, "True")
    case False{}:
      report(window, got)

def judged(+platform: String, f: Window & Image & List<Event>) -> IO(Unit):
  (window, image, events) = f
  +got = lines(events, "")
  verdict(String.eq(platform, "") || String.contains(got, want(platform)),
    window, got)

def fed(pair: Window & String) -> IO(Unit):
  (window, +platform) = pair
  do IO<Unit>:
    frame : Window & Image & List<Event> <- Window.frame(window, Pix{0})
    judged(platform, frame)

# Windowed, a request to leave fullscreen changes nothing (a desktop without
# fullscreen refuses it, keeping the window).
def kept(p: Window & Result<&1, &1, U32 & String, Unit>) -> IO(Unit):
  (window, r) = p
  match r:
    case Done{u}:
      do IO<Unit>:
        pair : Window & String <- fake(window)
        fed(pair)
    case Fail{e}:
      do IO<Unit>:
        pair : Window & String <- fake(window)
        fed(pair)

def opened(result: Result<&1, &1, U32 & String, Window>) -> IO(Unit):
  match result:
    case Done{window}:
      do IO<Unit>:
        p : Window & Result<&1, &1, U32 & String, Unit> <-
          Window.fullscreen(window, False{})
        kept(p)
    case Fail{(+code, message)}:
      IO.print(Bool.show(U32.is_eq(code, 45) || U32.is_eq(code, 95)))

def main() -> IO(Unit):
  do IO<Unit>:
    result : Result<&1, &1, U32 & String, Window> <- Window.open("Fullscreen",
      64, 48)
    opened(result)

#|True
