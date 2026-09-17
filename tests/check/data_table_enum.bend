# bend3's nullary-ctor enum had table [] -- always Data -- so a Token shared and
# owned freely. bend is affine for enums too: the free sharing becomes the
# explicit + binder (the enum is Data), and the same three flips answer the same
# 2.
# ported from bend3: t = (Token.Yes{} : Token) becomes a +let with the
# brace Ann; ctor names are bare
import Base

type Token is Data:
  Yes{}
  No{}

law flip:
  for t: Token
  U32

def flip(t):
  match t:
    case Yes{}:
      1
    case No{}:
      0

law main.out:
  U32

def main.out():
  +t = {Yes{} : Token}
  (flip(t) + flip(t) + flip(No{}) : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|2
