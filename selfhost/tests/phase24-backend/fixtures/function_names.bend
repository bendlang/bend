import Base

def a.b() -> Nat: 1n
def a_b() -> Nat: 2n
def A.b() -> Nat: 4n
def IO_EMIT() -> Nat: 8n
def EXIT() -> Nat: 16n
def ENTER() -> Nat: 32n
def main() -> Nat:
  Nat.add(Nat.add(a.b(), a_b()), Nat.add(A.b(), Nat.add(IO_EMIT(), Nat.add(EXIT(), ENTER()))))

#|63n
