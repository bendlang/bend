# red-team pin carried from bend3: a ctor field whose type is a FULL
# application of a Def type alias must check -- the alias answers Data
# (its kind is what the Data declaration reads), and the checker whnfs
# the field type, so alias(U32) reduces to U32 and a MkW2 builds and
# matches. No sharing here: the port is strict.
# ported from bend3: match heads a def body only, so the match moved
# into get; ctor names are bare and globally unique (W.K -> MkW2)
import Base

law alias:
  for T: Data
  Data

def alias(T):
  T

type W2 is Data:
  MkW2{v: alias(U32)}

law get:
  for w: W2
  U32

def get(w):
  match w:
    case MkW2{v}:
      v

law main.out:
  U32

def main.out():
  get({MkW2{42} : W2})

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|42
