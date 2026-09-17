# io (io_marshal_char_type): a Char and a String are both JS strings,
# told apart only by type -- and with one value model nothing needs
# telling: an answered Char IS the string the continuation matches
# on, directly (getc), inside a ctor field (Maybe<Char>), and through
# a dependent Sigma pair (Char & String). Both lanes run the same
# compiled text and print the same three lines byte-identically.
import Base

law getc:
  IO(Char)

def getc():
  import "./marshal_char_type.js"

law pick:
  IO(Maybe<&2, Char>)

def pick():
  import "./marshal_char_type.js"

law stamp:
  IO(Char & String)

def stamp():
  import "./marshal_char_type.js"

law code_of:
  for m: Maybe<&2, Char>
  U32

def code_of(m):
  match m:
    case None{}:
      0
    case Some{c}:
      match c:
        case Chr{n}:
          n

law pair_show:
  for p: Char & String
  String

def pair_show(p):
  match p:
    case Tuple{c, s}:
      String.append(U32.show(code_of(Some{c})), s)

law main:
  IO(U32)

def main():
  do IO<U32>:
    c : Char <- getc()
    t : Unit <- IO.print(U32.show(code_of(Some{c})))
    m : Maybe<&2, Char> <- pick()
    u : Unit <- IO.print(U32.show(code_of(m)))
    p : Char & String <- stamp()
    v : Unit <- IO.print(pair_show(p))
    return 0

#|65
#|90
#|113ok
