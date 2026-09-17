# A | B is core grammar (Either), gated on nothing but the name --
# with Base it is Either<A, B> (bend3 gated the bare | on `import
# Either`)
import Base

law pick:
  for e: U32 | Bool
  U32

def pick(e):
  match e:
    case Inl{u}:
      u
    case Inr{True{}}:
      1
    case Inr{False{}}:
      0

law main.out:
  U32

def main.out():
  (pick({Inl{7} : U32 | Bool}) * 10 + pick({Inr{True{}} : U32 | Bool}) : U32)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|71
