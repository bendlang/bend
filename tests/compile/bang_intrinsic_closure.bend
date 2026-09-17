# a banged under-applied intrinsic is pure-code value position, where
# SPEC 2.1 says the "!" mark is ignored: the spine must eta-expand to
# the same minted closure the unbanged spelling takes. Before this pin
# the inliner refused banged spines before its arity check, so the
# shape leaked to emission: the C backend printed the intrinsic macro
# under-applied (u32_add at one argument, a build failure) while the
# JS backend rendered a private closure lane -- a backend divergence
import Base

law main.out:
  U32

def main.out():
  f = {U32.add!(1) : U32 -> U32}
  f(2)

law main:
  IO(Unit)

def main():
  IO.print(U32.show(main.out()))

#|3
