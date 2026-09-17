# io (io_tcp_listen_close): the TCP surface at its smallest: listen
# binds a Listener handle over ./effs/tcp_listen, Listener.close
# releases it, IO.try unwraps the Result and would halt on Fail.
# Ported from bend3's listen/close pin, which awaited this surface.
import Base

law main:
  IO(U32)

def main():
  do IO<U32>:
    l : Listener <- IO.try(Listener, TCP.listen(19233))
    x : Unit <- Listener.close(l)
    p : Unit <- IO.print("closed")
    return 0

#|closed
