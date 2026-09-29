# io (io_poll_writer): a writer that drains what is queued into one
# commit, then blocks for the next value: it polls recv with 0 ms until
# Wait{rest}, commits, then resumes rest, so the recv that blocks is the
# one held in rest and nothing is taken between the drain and the wait.
# From #1162's case, by @aldeni.
import Base

def producer(+c: Chan(U32)) -> IO(Unit):
  do IO<Unit>:
    Unit <- IO.sleep(20)
    Bool <- Chan.send(U32, c, 4)
    Unit <- IO.sleep(20)
    Bool <- Chan.send(U32, c, 5)
    Bool <- Chan.send(U32, c, 6)
    Unit <- IO.sleep(20)
    Chan.close(U32, c)

def writer(fuel: Nat, +c: Chan(U32), batch: String, s: IO.Step<Maybe<&1, U32>>) -> IO(Unit):
  match fuel:
    case 0n:
      IO.print("out of fuel")
    case 1n+p:
      match s:
        case Ready{Some{x}}:
          IO.bind(IO.Step<Maybe<&1, U32>>, Unit,
            IO.poll(Maybe<&1, U32>, 0, Chan.recv(U32, c)),
            writer(p, c, batch ++ " " ++ U32.show(x)))
        case Ready{None{}}:
          IO.print("commit" ++ batch ++ ", closed")
        case Wait{rest}:
          IO.bind(Unit, Unit, IO.print("commit" ++ batch), u =>
            IO.bind(Maybe<&1, U32>, Unit, IO.resume(Maybe<&1, U32>, rest),
              m => writer(p, c, "", Ready{m})))

def run(c: Chan(U32)) -> IO(Unit):
  +ch = c
  do IO<Unit>:
    Bool <- Chan.send(U32, ch, 1)
    Bool <- Chan.send(U32, ch, 2)
    Bool <- Chan.send(U32, ch, 3)
    Unit <- IO.spawn(Unit, producer(ch))
    s : IO.Step<Maybe<&1, U32>> <- IO.poll(Maybe<&1, U32>, 0, Chan.recv(U32, ch))
    writer(100n, ch, "", s)

def main() -> IO(Unit):
  IO.bind(Chan(U32), Unit, Chan.new(U32, 8), run)

#|commit 1 2 3
#|commit 4
#|commit 5 6
#|commit, closed
