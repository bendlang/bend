# gfx (gfx_window_events): events through window.c's own handlers. On X11,
# feed (window_events.c) hands the window XInput2 events of a touch screen,
# a pen and a touchpad (the mouse). On the Mac it moves and clicks the
# mouse. Each event the test made (a pointer's at time 4000000000 on) is a
# line, forces in hundredths: True once they are its platform's, else the
# lines after 200 frames. Without a display, True, as window_title.
import Base

def feed(window: Window) -> IO(Window & String):
  import "./window_events.c"
  import "./window_events.js"

def hundredths(x: F32) -> String:
  F32.show(F32.round((x * 100.0 : F32)))

def tool(t: Tool) -> String:
  match t:
    case Tool.Mouse{}:
      "mouse"
    case Tool.Finger{force, width, height}:
      "finger " ++ hundredths(force)
    case Tool.Pen{force, tangential, tilt_x, tilt_y, twist}:
      "pen " ++ hundredths(force) ++ " " ++ F32.show(tilt_x)

def mine(+time: U32, s: String) -> String:
  Bool.pick(String, U32.is_ge(time, 4000000000),
    s ++ " " ++ U32.show(time) ++ "\n", "")

# An event's line, if the test made it.
def line(e: Event) -> String:
  match e:
    case Press{id, t, x, y, +time, button, down}:
      mine(time, "press " ++ U32.show(id) ++ " " ++ tool(t) ++ " "
        ++ F32.show(x) ++ " " ++ F32.show(y) ++ " " ++ U32.show(button) ++ " "
        ++ Bool.show(down))
    case Move{id, t, x, y, +time}:
      mine(time, "move " ++ U32.show(id) ++ " " ++ tool(t) ++ " "
        ++ F32.show(x) ++ " " ++ F32.show(y))
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
    "move 0 mouse 5 6 4000000007\n"
      ++ "press 0 mouse 5 6 0 True 4000000008\n"
      ++ "press 0 mouse 5 6 0 False 4000000009\n",
    "press 1 finger 100 10 20 0 True 4000000001\n"
      ++ "move 1 finger 50 12 20 4000000002\n"
      ++ "press 1 finger 0 12 20 0 False 4000000003\n"
      ++ "move 1 pen 0 30 30 40 4000000004\n"
      ++ "press 1 pen 50 30 30 40 0 True 4000000005\n"
      ++ "press 1 pen 0 30 30 40 0 False 4000000006\n"
      ++ "move 0 mouse 5 6 4000000007\n"
      ++ "press 0 mouse 5 6 0 True 4000000008\n"
      ++ "press 0 mouse 5 6 0 False 4000000009\n")

def report(window: Window, text: String) -> IO(Unit):
  do IO<Unit>:
    Window.close(window)
    IO.print(text)

def until(
  done: Bool, window: Window, got: String, rest: Window -> String -> IO(Unit)
) -> IO(Unit):
  match done:
    case True{}:
      report(window, "True")
    case False{}:
      rest(window, got)

def step(
  +platform: String, f: Window & Image & List<Event>, got: String,
  rest: Window -> String -> IO(Unit)
) -> IO(Unit):
  (window, image, events) = f
  +now = lines(events, got)
  until(String.eq(now, want(platform)), window, now, rest)

def watch(fuel: Nat, +platform: String, window: Window, got: String) ->
  IO(Unit):
  match fuel:
    case 0n:
      report(window, got)
    case 1n+f:
      do IO<Unit>:
        frame : Window & Image & List<Event> <- Window.frame(window, Pix{0})
        step(platform, frame, got, w => g => watch(f, platform, w, g))

def fed(pair: Window & String) -> IO(Unit):
  (window, platform) = pair
  watch(200n, platform, window, "")

def opened(result: Result<&1, &1, U32 & String, Window>) -> IO(Unit):
  match result:
    case Done{window}:
      do IO<Unit>:
        pair : Window & String <- feed(window)
        fed(pair)
    case Fail{(+code, message)}:
      IO.print(Bool.show(U32.is_eq(code, 45) || U32.is_eq(code, 95)))

def main() -> IO(Unit):
  do IO<Unit>:
    result : Result<&1, &1, U32 & String, Window> <- Window.open("Events", 64,
      48)
    opened(result)

#|True
