# io (io_chan_close_send): a send answers True while the channel is
# open and False once it is closed, on every lane (the JS backend's
# Bool is a native boolean: the kit must answer one).
import Base

law show:
  for b: Bool
  String

def show(b):
  match b:
    case False{}:
      "False"
    case True{}:
      "True"

law main.go:
  for c: Chan(U32)
  IO(U32)

def main.go(c):
  +ch = c
  do IO<U32>:
    a : Bool <- Chan.send(U32, ch, 1)
    Unit <- Chan.close(U32, ch)
    b : Bool <- Chan.send(U32, ch, 2)
    Unit <- IO.print(String.append(show(a), show(b)))
    return 0

law main:
  IO(U32)

def main():
  IO.bind(Chan(U32), U32, Chan.new(U32, 2), main.go)

#|TrueFalse
