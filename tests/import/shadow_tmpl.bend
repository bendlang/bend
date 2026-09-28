# an instance of a module's template is that template's body at its ~
# arguments, the body the checker reasons about: M.F names Base's Nat.add
# and M.G the module's pick, not this file's, so the lemmas state 3n and
# 0n, and every lane prints (3n, 0n). once an instance was re-parsed at
# the call, where the caller's own names stood
import Base
import ./shadow_tmpl_lib.bend as M

def pick(a: Nat, b: Nat) -> Nat:
  Nat.add(a, b)

def lemma_f() -> {M.F(~1n, 2n) == 3n : Nat}:
  {==}

def lemma_g() -> {M.G(~1n, 2n) == 0n : Nat}:
  {==}

def main() -> (Nat & Nat):
  (M.F(~1n, 2n), M.G(~1n, 2n))

#|(3n, 0n)
