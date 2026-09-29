# io (io_poll_nested): a poll inside another's act waits no longer than the
# outer one: an inner poll of 2000 ms under an outer one of 20 ms is
# cancelled at 20 ms, and both answer Late.
import Base

def later(ms: U32, ch: Chan(U32), x: U32) -> IO(Bool):
  IO.bind(Unit, Bool, IO.sleep(ms), u => Chan.send(U32, ch, x))

def got(m: Maybe<&1, U32>) -> String:
  match m:
    case None{}:
      "none"
    case Some{value}:
      U32.show(value)

def step(p: IO.Poll<Maybe<&1, U32>>) -> String:
  match p:
    case Ready{value}:
      "ready " ++ got(value)
    case Late{value}:
      "late " ++ got(value)

def inner(ch: Chan(U32)) -> IO(Maybe<&1, U32>):
  IO.bind(IO.Poll<Maybe<&1, U32>>, Maybe<&1, U32>,
    IO.poll(Maybe<&1, U32>, 2000, Chan.recv(U32, ch)), p =>
      IO.bind(Unit, Maybe<&1, U32>, IO.print("inner: " ++ step(p)),
        u => IO.pure(Maybe<&1, U32>, None{})))

def run(c: Chan(U32)) -> IO(Unit):
  +ch = c
  do IO<Unit>:
    Unit <- IO.spawn(Bool, later(1000, ch, 9))
    r : IO.Poll<Maybe<&1, U32>> <- IO.poll(Maybe<&1, U32>, 20, inner(ch))
    Unit <- IO.print("outer: " ++ step(r))
    m : Maybe<&1, U32> <- Chan.recv(U32, ch)
    IO.print("the value stays: " ++ got(m))

def main() -> IO(Unit):
  IO.bind(Chan(U32), Unit, Chan.new(U32, 0), run)

#|inner: late none
#|outer: late none
#|the value stays: 9
