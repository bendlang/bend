# io (io_poll): IO.poll(ms, act) runs act, but an effect in act that would
# wait more than ms is cancelled instead: it answers at once, unrun (a send
# False, a recv None, a sleep Unit), and act goes on with that answer.
# IO.poll answers Ready{x}, or Late{x} once something was cancelled. A
# cancelled send puts nothing in the channel.
import Base

def tell(-A: Type, name: String, p: IO.Poll<A>, show: A -> String) -> IO(Unit):
  match p:
    case Ready{value}:
      IO.print(name ++ ": ready " ++ show(value))
    case Late{value}:
      IO.print(name ++ ": late " ++ show(value))

def got(m: Maybe<&1, U32>) -> String:
  match m:
    case None{}:
      "none"
    case Some{value}:
      U32.show(value)

def unit(u: Unit) -> String:
  "()"

def chans(c: Chan(U32)) -> IO(U32):
  +ch = c
  do IO<U32>:
    r1 : IO.Poll<Maybe<&1, U32>> <- IO.poll(Maybe<&1, U32>, 0, Chan.recv(U32, ch))
    Unit <- tell(Maybe<&1, U32>, "recv empty", r1, got)
    s1 : IO.Poll<Bool> <- IO.poll(Bool, 0, Chan.send(U32, ch, 7))
    Unit <- tell(Bool, "send room", s1, Bool.show)
    s2 : IO.Poll<Bool> <- IO.poll(Bool, 0, Chan.send(U32, ch, 8))
    Unit <- tell(Bool, "send full", s2, Bool.show)
    r2 : IO.Poll<Maybe<&1, U32>> <- IO.poll(Maybe<&1, U32>, 0, Chan.recv(U32, ch))
    Unit <- tell(Maybe<&1, U32>, "recv one", r2, got)
    r3 : IO.Poll<Maybe<&1, U32>> <- IO.poll(Maybe<&1, U32>, 0, Chan.recv(U32, ch))
    Unit <- tell(Maybe<&1, U32>, "recv, the cancelled send not in", r3, got)
    Unit <- Chan.close(U32, ch)
    r4 : IO.Poll<Maybe<&1, U32>> <- IO.poll(Maybe<&1, U32>, 0, Chan.recv(U32, ch))
    Unit <- tell(Maybe<&1, U32>, "recv closed", r4, got)
    return 0

def naps() -> IO(U32):
  do IO<U32>:
    z1 : IO.Poll<Unit> <- IO.poll(Unit, 0, IO.sleep(30))
    Unit <- tell(Unit, "sleep 30, 0 ms", z1, unit)
    z2 : IO.Poll<Unit> <- IO.poll(Unit, 10, IO.sleep(30))
    Unit <- tell(Unit, "sleep 30, 10 ms", z2, unit)
    z3 : IO.Poll<Unit> <- IO.poll(Unit, 100, IO.sleep(30))
    Unit <- tell(Unit, "sleep 30, 100 ms", z3, unit)
    return 0

def two(d: Chan(U32)) -> IO(U32):
  +ch = d
  act = IO.bind(Unit, U32, IO.print("before"), u =>
    IO.bind(Maybe<&1, U32>, U32, Chan.recv(U32, ch), m =>
      IO.bind(Unit, U32, IO.print("after, got " ++ got(m)), v => IO.pure(U32, 5))))
  do IO<U32>:
    p : IO.Poll<U32> <- IO.poll(U32, 0, act)
    Unit <- tell(U32, "three effects, the recv cancelled", p, U32.show)
    return 0

def main() -> IO(U32):
  do IO<U32>:
    c : Chan(U32) <- Chan.new(U32, 1)
    a : U32 <- chans(c)
    b : U32 <- naps()
    d : Chan(U32) <- Chan.new(U32, 0)
    two(d)

#|recv empty: late none
#|send room: ready True
#|send full: late False
#|recv one: ready 7
#|recv, the cancelled send not in: late none
#|recv closed: ready none
#|sleep 30, 0 ms: late ()
#|sleep 30, 10 ms: late ()
#|sleep 30, 100 ms: ready ()
#|before
#|after, got none
#|three effects, the recv cancelled: late 5
