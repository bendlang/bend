# io (io_chan_try_gone_bound): try_ receivers that time out behind a receiver
# that is never woken do not pile up in the channel's queue. 5000 park
# behind it for 1 ms each; once they are all gone, the queue holds the live
# one and at most 65 gone. JS only: Peek.waiters reads the queue's length.
import Base

def Peek.waiters(c: Chan(U32)) -> IO(U32):
  import "./chan_try_gone_bound.js"

def first(c: Chan(U32)) -> IO(Unit):
  IO.bind(Maybe<&1, U32>, Unit, Chan.recv(U32, c), r => IO.pure(Unit, Unit{}))

def short(c: Chan(U32)) -> IO(Unit):
  IO.bind(Poll<&1, &1, Maybe<&1, U32>, Unit>, Unit, Chan.try_recv(U32, c, 1), r => IO.pure(Unit, Unit{}))

def spawn_all(n: Nat, +c: Chan(U32)) -> IO(Unit):
  match n:
    case 0n:
      IO.pure(Unit, Unit{})
    case 1n+p:
      do IO<Unit>:
        u : Unit <- IO.spawn(Unit, short(c))
        spawn_all(p, c)

def told(ok: Bool, n: U32) -> String:
  match ok:
    case True{}:
      "bounded"
    case False{}:
      "piled up: " ++ U32.show(n)

def bounded(+n: U32) -> String:
  told(U32.is_le(n, 66), n)

def main() -> IO(Unit):
  do IO<Unit>:
    +c : Chan(U32) <- Chan.new(U32, 0)
    a : Unit <- IO.spawn(Unit, first(c))
    b : Unit <- spawn_all(5000n, c)
    s : Unit <- IO.sleep(100)
    n : U32 <- Peek.waiters(c)
    p : Unit <- IO.print(bounded(n))
    r : Result<&1, &1, U32, Unit> <- Chan.send(U32, c, 0)
    IO.print("ok")

#|bounded
#|ok
