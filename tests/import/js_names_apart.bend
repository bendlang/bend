# a def's JS name keeps its key's / - and ~ apart from its dots: the
# module has-hyphen/lib's two and this file's has.hyphen.lib.two were
# both $has$hyphen$lib$two$, and the JS build refused them (as #790 and
# #989 did for a C id)
import Base
import ./has-hyphen/lib.bend as L

def has.hyphen.lib.two() -> Nat:
  20n

def main() -> IO(Unit):
  IO.print(Nat.show(Nat.add(L.two(), has.hyphen.lib.two())))

#|22
