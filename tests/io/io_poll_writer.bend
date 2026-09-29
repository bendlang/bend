# io (io_poll_writer): a writer that drains what is queued into one
# commit, then blocks for the next value: it polls recv with 0 ms until
# Late, commits, then recvs; the cancelled recv took nothing, so no value
# is lost between the drain and the wait. A polled value and a received
# one go to the same handler, got. From #1162's case, by @aldeni.
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

# a value for the batch: add it and go on, or commit at the close
def got(batch: String, m: Maybe<&1, U32>, more: String -> IO(Unit)) -> IO(Unit):
  match m:
    case Some{value}:
      more(batch ++ " " ++ U32.show(value))
    case None{}:
      IO.print("commit" ++ batch ++ ", closed")

# a poll's answer: a value now, or commit and block for the next one
def polled(batch: String, p: IO.Poll<Maybe<&1, U32>>, next: IO(Maybe<&1, U32>),
  more: String -> IO(Unit)) -> IO(Unit):
  match p:
    case Ready{value}:
      got(batch, value, more)
    case Late{value}:
      do IO<Unit>:
        Unit <- IO.print("commit" ++ batch)
        m : Maybe<&1, U32> <- next
        got("", m, more)

def drain(fuel: Nat, +c: Chan(U32), batch: String) -> IO(Unit):
  match fuel:
    case 0n:
      IO.print("out of fuel")
    case 1n+p:
      IO.bind(IO.Poll<Maybe<&1, U32>>, Unit,
        IO.poll(Maybe<&1, U32>, 0, Chan.recv(U32, c)),
        s => polled(batch, s, Chan.recv(U32, c), b => drain(p, c, b)))

def run(c: Chan(U32)) -> IO(Unit):
  +ch = c
  do IO<Unit>:
    Bool <- Chan.send(U32, ch, 1)
    Bool <- Chan.send(U32, ch, 2)
    Bool <- Chan.send(U32, ch, 3)
    Unit <- IO.spawn(Unit, producer(ch))
    drain(100n, ch, "")

def main() -> IO(Unit):
  IO.bind(Chan(U32), Unit, Chan.new(U32, 8), run)

#|commit 1 2 3
#|commit 4
#|commit 5 6
#|commit, closed
