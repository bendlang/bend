# A resizable app receives pixel dimensions before its next view; later
# events can replace the dimensions, while Close still stops the run.
import Base

type Size is Data:
  Size{width: U32, height: U32}

def update(events: List<Event>, state: Size) -> Maybe<Size>:
  match events:
    case Nil{}:
      Some{state}
    case Resize{width, height} <> rest:
      update(rest, Size{width, height})
    case Close{} <> rest:
      None{}
    case event <> rest:
      update(rest, state)

def tick(events: List<Event>, state: Size) -> IO(Maybe<Size>):
  IO.pure(Maybe<Size>, update(events, state))

def view(state: Size) -> Size & Image:
  Size{+width, +height} = state
  (Size{width, height}, Pix{(width * height : U32)})

def show(result: Maybe<Size>) -> IO(Unit):
  match result:
    case None{}:
      IO.print("closed")
    case Some{Size{width, height}}:
      IO.print(U32.show(width) ++ "x" ++ U32.show(height))

def main() -> IO(Unit):
  do IO<Unit>:
    first : Maybe<Size> <- App.play(~Size, ~App{view, tick},
      [[Resize{96, 64}], [Key{65, True{}}, Resize{32, 24}], []],
      Size{64, 48})
    u : Unit <- show(first)
    second : Maybe<Size> <- App.play(~Size, ~App{view, tick},
      [[Resize{1, 1}, Close{}, Resize{2, 2}]], Size{64, 48})
    show(second)

#|32x24
#|closed
