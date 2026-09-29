# io (io_poll_timers): a timed channel poll's deadline belongs to its own
# wait. Answered early, it leaves nothing armed on the channel: a plain
# recv after it, a second timed poll, and another computation's poll each
# wait for their own value (the shapes of @Lorenzobattistela's review of
# #1172, which crashed on C and answered twice on JS).
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

def plain(c: Chan(U32)) -> IO(Unit):
  +ch = c
  do IO<Unit>:
    Unit <- IO.spawn(Bool, later(10, ch, 1))
    r : IO.Poll<Maybe<&1, U32>> <- IO.poll(Maybe<&1, U32>, 100, Chan.recv(U32, ch))
    Unit <- IO.print("poll: " ++ step(r))
    Unit <- IO.spawn(Bool, later(250, ch, 2))
    m : Maybe<&1, U32> <- Chan.recv(U32, ch)
    IO.print("then a recv: " ++ got(m))

def twice(c: Chan(U32)) -> IO(Unit):
  +ch = c
  do IO<Unit>:
    Unit <- IO.spawn(Bool, later(10, ch, 1))
    r : IO.Poll<Maybe<&1, U32>> <- IO.poll(Maybe<&1, U32>, 100, Chan.recv(U32, ch))
    Unit <- IO.print("first: " ++ step(r))
    Unit <- IO.spawn(Bool, later(250, ch, 2))
    s : IO.Poll<Maybe<&1, U32>> <- IO.poll(Maybe<&1, U32>, 500, Chan.recv(U32, ch))
    IO.print("second: " ++ step(s))

def poller(name: String, ms: U32, ch: Chan(U32)) -> IO(Unit):
  IO.bind(IO.Poll<Maybe<&1, U32>>, Unit,
    IO.poll(Maybe<&1, U32>, ms, Chan.recv(U32, ch)), p => IO.print(name ++ ": " ++ step(p)))

def two(c: Chan(U32)) -> IO(Unit):
  +ch = c
  do IO<Unit>:
    Unit <- IO.spawn(Unit, poller("B", 400, ch))
    Unit <- IO.sleep(10)
    Unit <- IO.spawn(Bool, later(150, ch, 7))
    poller("A", 30, ch)

def main() -> IO(Unit):
  do IO<Unit>:
    a : Chan(U32) <- Chan.new(U32, 0)
    Unit <- plain(a)
    b : Chan(U32) <- Chan.new(U32, 0)
    Unit <- twice(b)
    c : Chan(U32) <- Chan.new(U32, 0)
    two(c)

#|poll: ready 1
#|then a recv: 2
#|first: ready 1
#|second: ready 2
#|A: late none
#|B: ready 7
