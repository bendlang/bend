# io (io_poll_drop): a dropped Wait{rest} leaves nothing behind, as a
# bounded queue relies on. A send polled on a full channel and dropped
# never delivers its value: once the queue is drained, a recv finds
# nothing. A recv polled on an empty channel with no room and dropped
# leaves no waiter: the next send reaches the next receiver, not the
# dropped one (which would take it and leave that receiver waiting).
import Base

def tell(-A: Type, name: String, s: IO.Step<A>) -> IO(Unit):
  match s:
    case Ready{value}:
      IO.print(String.append(name, ": ready"))
    case Wait{rest}:
      IO.print(String.append(name, ": wait, dropped"))

def got(m: Maybe<&1, U32>) -> String:
  match m:
    case None{}:
      "none"
    case Some{value}:
      U32.show(value)

def sends(c: Chan(U32)) -> IO(Unit):
  +ch = c
  do IO<Unit>:
    Bool <- Chan.send(U32, ch, 1)
    s : IO.Step<Bool> <- IO.poll(Bool, 0, Chan.send(U32, ch, 2))
    Unit <- tell(Bool, "send 2 on a full queue", s)
    m : Maybe<&1, U32> <- Chan.recv(U32, ch)
    Unit <- IO.print(String.append("drained: ", got(m)))
    r : IO.Step<Maybe<&1, U32>> <- IO.poll(Maybe<&1, U32>, 0, Chan.recv(U32, ch))
    tell(Maybe<&1, U32>, "then a recv, 2 never sent", r)

def receiver(ch: Chan(U32)) -> IO(Unit):
  IO.bind(Maybe<&1, U32>, Unit, Chan.recv(U32, ch), m =>
    IO.print(String.append("the next receiver got ", got(m))))

def recvs(c: Chan(U32)) -> IO(Unit):
  +ch = c
  do IO<Unit>:
    r : IO.Step<Maybe<&1, U32>> <- IO.poll(Maybe<&1, U32>, 0, Chan.recv(U32, ch))
    Unit <- tell(Maybe<&1, U32>, "recv on an empty channel", r)
    Unit <- IO.spawn(Unit, receiver(ch))
    ok : Bool <- Chan.send(U32, ch, 7)
    IO.print(String.append("send 7: ", Bool.show(ok)))

def main() -> IO(Unit):
  do IO<Unit>:
    q : Chan(U32) <- Chan.new(U32, 1)
    Unit <- sends(q)
    c : Chan(U32) <- Chan.new(U32, 0)
    recvs(c)

#|send 2 on a full queue: wait, dropped
#|drained: 1
#|then a recv, 2 never sent: wait, dropped
#|recv on an empty channel: wait, dropped
#|the next receiver got 7
#|send 7: True
