# bend3's specialization law retyped a hypothesis inside a computed
# match's arm, with `as e` binding the equation beside it; bend's
# computed match never specializes (check_computed_match_split pins
# that) and has no as binder -- the spelling dies at the extra
# scrutinee, before any retyping question
import Base

law nat_eq:
  for a: Nat
  for b: Nat
  Bool

def nat_eq(a, b):
  Cmp.is_eq(Nat.cmp(a, b))

law use:
  for a: Bool
  for b: Bool
  for h: {Bool.and(a, b) == False{} : Bool}
  Bool

def use(a, b, h):
  True{}

law repro:
  for n: Nat
  for m: Nat
  for h: {Bool.and(nat_eq(n, m), False{}) == False{} : Bool}
  Bool

def repro(n, m, h):
  match nat_eq(n, m) as e:
    case True{}:
      use(True{}, False{}, h)
    case False{}:
      False{}

law main:
  Bool

def main():
  repro(0n, 0n, {==})

#|Error:
#|- expected : 3 patterns (one per scrutinee)
#|- observed : 'True{}'
#|Location:
#|32 |   match nat_eq(n, m) as e:
#|33>|     case True{}:
#|   |          ^^^^^^
#|34 |       use(True{}, False{}, h)
#|exit 1
