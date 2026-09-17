# bend3's C-namer livelock on machine-spelled locals (K_*, drop_*,
# state_*, arm_*, t9); bend's emitter namespaces user locals apart
# from the machine's, so the same adversarial names compile and the
# value answers on every lane
import Base

law f6:
  U32 -> U32 -> U32

def f6():
  drop_x => state_y => (drop_x + state_y : U32)

law main.out:
  Nat

def main.out():
  K = {5 : U32}
  arm_z = {8 : U32}
  t9 = {9 : U32}
  U32.to_nat((f6()(K, 6) + (7 + (arm_z + t9)) : U32))

law main:
  IO(Unit)

def main():
  IO.print(String.append(Nat.show(main.out()), "n"))

#|35n
