# io (io_marshal_string_scalar): an effect's String answer is walked by
# Char in every lane. Valid host text needs no str_in: the boundary
# scalars (55295, 57344, 1114111) cross as one-Char strings, and a Char
# answer's code reads back exact. A host's lone surrogate comes in as
# U+FFFD through the effect's str_in: torn ("a" then D800) reads 97 then
# 65533 (55296 without str_in), and torn_low ("a", DC00, "bcd") counts 5,
# where a DC00 left in would read as the head of one packed Char and count
# 2.
import Base

law low:
  IO(String)

def low():
  import "./marshal_string_scalar.js"

law high:
  IO(String)

def high():
  import "./marshal_string_scalar.js"

law apex:
  IO(String)

def apex():
  import "./marshal_string_scalar.js"

law edge:
  IO(Char)

def edge():
  import "./marshal_string_scalar.js"

law torn:
  IO(String)

def torn():
  import "./marshal_string_scalar.js"

law torn_low:
  IO(String)

def torn_low():
  import "./marshal_string_scalar.js"

law count:
  for s: String
  U32

def count(s):
  match s:
    case SNil{}:
      0
    case SCon{h, t}:
      U32.add(1, count(t))

law code_of:
  for c: Char
  U32

def code_of(c):
  match c:
    case Chr{n}:
      n

law codes:
  for s: String
  String

def codes(s):
  match s:
    case SNil{}:
      ""
    case SCon{h, t}:
      U32.show(Char.to_u32(h)) ++ ";" ++ codes(t)

law main:
  IO(U32)

def main():
  do IO<U32>:
    a : String <- low()
    b : String <- high()
    c : String <- apex()
    d : Char <- edge()
    e : String <- torn()
    f : String <- torn_low()
    u : Unit <- IO.print(U32.show(count(a)))
    v : Unit <- IO.print(U32.show(count(b)))
    w : Unit <- IO.print(U32.show(count(c)))
    x : Unit <- IO.print(U32.show(code_of(d)))
    y : Unit <- IO.print(codes(e))
    z : Unit <- IO.print(U32.show(count(f)))
    return 0

#|1
#|1
#|1
#|55295
#|97;65533;
#|5
