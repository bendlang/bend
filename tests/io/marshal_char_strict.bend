# io (io_marshal_char_strict): the seam has ONE value model -- a Char
# and a String are both JS strings, and an effect's answer is trusted
# inbound in every lane. This golden pinned the dead two-model
# refusal ('a one-Char string answer'): the interpreter refused a
# two-code-point Char where compiled JS kept the whole string. Now
# both lanes run the same text: star answers a real Char, wide
# appends to it, and the widened value prints whole -- both lanes
# print "gb" byte-identically, which is the law this golden guards
# (the old one-byte-vs-two output divergence cannot exist with one
# model).
import Base

law star:
  IO(Char)

def star():
  import "./marshal_char_strict.js"

law wide:
  for c: Char
  IO(Char)

def wide(c):
  import "./marshal_char_strict.js"

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    a : Char <- star()
    b : Char <- wide(a)
    IO.print(SCon{b, SNil{}})

#|gb
