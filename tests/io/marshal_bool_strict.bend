# io (io_marshal_bool_strict): the seam has ONE value model -- the
# interpreter runs the compiled JS itself, so an effect's answer is
# whatever the .js body returns, trusted inbound in every lane. This
# golden pinned the dead two-model refusal ('a boolean Bool answer'):
# the interpreter marshaled answers by type and refused a 1 where
# compiled JS ran it. Now both lanes run the SAME text: flop's real
# boolean rides the honest round trip, loose answers 1 at Bool, and
# the Bool match runs it as truthy -- both lanes print "wide"
# byte-identically, which is the law this golden now guards (the
# verdict rides a worker def: the if sugar is gone).
import Base

law flop:
  for b: Bool
  IO(Bool)

def flop(b):
  import "./marshal_bool_strict.js"

law loose:
  for c: Bool
  IO(Bool)

def loose(c):
  import "./marshal_bool_strict.js"

law word:
  for c: Bool
  String

def word(c):
  match c:
    case True{}:
      "wide"
    case False{}:
      "open"

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    b : Bool <- flop(True{})
    c : Bool <- loose(b)
    IO.print(word(c))

#|wide
