# io (io_tcp_connect_black_hole): a connect to an address that drops
# packets (TEST-NET-1, or one the network refuses at once) must not
# stop the loop: the socket is non-blocking, EINPROGRESS parks the
# connecting computation until the socket is writable, and main's
# three timers land on time. The connect may still be pending when
# main is done, so main ends the process itself with IO.die code 0.
# Before this, the JS lane's connect blocked the loop thread for the
# kernel's 75 s and the ticks came after it.
import Base

def probe.got(r: Result<&1, &1, (U32 & String), Socket>) -> IO(Unit):
  match r:
    case Done{s}:
      Socket.close(s)
    case Fail{e}:
      IO.pure(Unit, Unit{})

def probe() -> IO(Unit):
  do IO<Unit>:
    r : Result<&1, &1, (U32 & String), Socket> <- TCP.connect("192.0.2.1", 80)
    probe.got(r)

def ticks(n: Nat) -> IO(Unit):
  match n:
    case 0n:
      IO.print("ticks done")
    case 1n+p:
      do IO<Unit>:
        Unit <- IO.sleep(100)
        Unit <- IO.print("tick")
        ticks(p)

def main() -> IO(U32):
  do IO<U32>:
    Unit <- IO.spawn(Unit, probe())
    Unit <- ticks(3n)
    IO.die(U32, 0, "")

#|tick
#|tick
#|tick
#|ticks done
