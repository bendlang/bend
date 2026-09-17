# io (io_udp_bad_address): a numeric IPv4 host is a CANONICAL decimal
# quad -- four parts, 0..255, no leading zeros -- and both kits parse
# it with the one shared rule: a malformed host answers Fail(EINVAL)
# in every backend. The C kit once rode inet_pton, whose macOS build
# reads a leading-zero quad as decimal while glibc refuses it, so
# "0127.0.0.1" sent a real datagram in C where JS refused; earlier
# the JS codec read Number("") as 0, so "1.2.3." sent to 1.2.3.0
# where C refused. ONE socket threads through every probe: the
# handle rides OUTSIDE the Result, so it survives five Fails and
# still sends -- the failure paths once dropped it, and a failed op
# leaked its handle forever.
import Base

law answer:
  for m: Socket & Result<&1, &1, (U32 & String), Unit>
  IO(Socket)

def answer(m):
  (s, r) = m
  match r:
    case Done{value}:
      do IO<Socket>:
        p : Unit <- IO.print("sent")
        return s
    case Fail{error}:
      (code, message) = error
      do IO<Socket>:
        p : Unit <- IO.print(message)
        return s

law probe:
  for s    : Socket
  for host : String
  IO(Socket)

def probe(s, host):
  do IO<Socket>:
    m : Socket & Result<&1, &1, (U32 & String), Unit> <- UDP.send_to(s, host, 9, "x")
    answer(m)

law main:
  IO(U32)

def main():
  do IO<U32>:
    s : Socket <- IO.try(Socket, UDP.bind(0))
    a : Socket <- probe(s, "1.2.3.")
    b : Socket <- probe(a, "1.2.3.256")
    c : Socket <- probe(b, "1.2.3")
    d : Socket <- probe(c, "0127.0.0.1")
    g : Socket <- probe(d, "010.0.0.1")
    h : Socket <- probe(g, "127.0.0.1")
    x : Unit <- Socket.close(h)
    return 0

#|Invalid argument
#|Invalid argument
#|Invalid argument
#|Invalid argument
#|Invalid argument
#|sent
