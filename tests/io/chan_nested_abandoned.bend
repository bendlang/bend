# A nested IO may exit while its sender is parked behind a live sender.
# Repeated exits must release those senders without waiting for the head.
# JS-only: the host runs nested IO and inspects the channel queue.
import Base

def Host.abandon(c: Chan(U32)) -> IO(U32):
  import "./chan_nested_abandoned.js"

def blocked(c: Chan(U32)) -> IO(Unit):
  IO.bind(Result<&1, &1, U32, Unit>, Unit, Chan.send(U32, c, 1), r => IO.pure(Unit, Unit{}))

def bounded_go(n: U32, ok: Bool) -> String:
  match ok:
    case True{}: "bounded"
    case False{}: "piled up: " ++ U32.show(n)

def bounded(+n: U32) -> String:
  bounded_go(n, U32.is_le(n, 66))

def main() -> IO(Unit):
  do IO<Unit>:
    +c : Chan(U32) <- Chan.new(U32, 0)
    Unit <- IO.spawn(Unit, blocked(c))
    Unit <- IO.sleep(1)
    n : U32 <- Host.abandon(c)
    Unit <- IO.print(bounded(n))
    Chan.close(U32, c)

#|bounded
