# io (io_poll_yield): a cancel yields to the other computations, as a wait
# would, so a loop of IO.poll(0, recv) lets a spawned sender run and gets
# its value (on C it used to spin and starve the sender).
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

def spin(n: Nat, +ch: Chan(U32), p: IO.Poll<Maybe<&1, U32>>) -> IO(Unit):
  match n:
    case 0n:
      IO.print("out of fuel")
    case 1n+k:
      match p:
        case Ready{value}:
          IO.print("got " ++ got(value))
        case Late{value}:
          IO.bind(IO.Poll<Maybe<&1, U32>>, Unit,
            IO.poll(Maybe<&1, U32>, 0, Chan.recv(U32, ch)), q => spin(k, ch, q))

def run(c: Chan(U32)) -> IO(Unit):
  +ch = c
  do IO<Unit>:
    Unit <- IO.spawn(Bool, Chan.send(U32, ch, 7))
    p : IO.Poll<Maybe<&1, U32>> <- IO.poll(Maybe<&1, U32>, 0, Chan.recv(U32, ch))
    spin(1000n, ch, p)

def main() -> IO(Unit):
  IO.bind(Chan(U32), Unit, Chan.new(U32, 0), run)

#|got 7
