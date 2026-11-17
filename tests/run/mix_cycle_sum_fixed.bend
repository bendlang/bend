# #2188 x #2175 x #2180: tail cycles, sum loops and fixed calls in one program.
import Base

# a flat two-def cycle (a head and a helper)
@unsafe
def cyc.if(even: Bool, +n: Nat, steps: Nat) -> Nat:
  match even:
    case True{}:
      cyc(Nat.div(n, 2n), 1n+steps)
    case False{}:
      cyc(Nat.add(Nat.mul(n, 3n), 1n), 1n+steps)

@unsafe
def cyc(+n: Nat, steps: Nat) -> Nat:
  match n:
    case 0n:
      steps
    case 1n:
      steps
    case 1n+p:
      cyc.if(Nat.is_eq(Nat.mod(n, 2n), 0n), n, steps)

# a: a sum loop (#2175) whose operand calls into the cycle
def suma(+i: Nat) -> Nat:
  match i:
    case 0n:
      0n
    case 1n+p:
      Nat.add(cyc(i, 0n), suma(p))

# c: a sum loop whose operand is fixed for the recursion (#2180 inside d~acc)
def sumc(+i: Nat, +k: Nat) -> Nat:
  match i:
    case 0n:
      0n
    case 1n+p:
      Nat.add(cyc(k, 0n), sumc(p, k))

# b: a cycle whose member adds a self call in its tail: #2175 leaves it alone
@unsafe
def ma(+n: Nat, acc: Nat) -> Nat:
  match n:
    case 0n:
      acc
    case 1n+p:
      mb(p, Nat.is_eq(Nat.mod(p, 3n), 0n), Nat.add(acc, 2n))

@unsafe
def mb(+n: Nat, t: Bool, acc: Nat) -> Nat:
  match n:
    case 0n:
      acc
    case 1n:
      1n+acc
    case 2n+p:
      match t:
        case True{}:
          Nat.add(7n, mb(1n+p, False{}, acc))
        case False{}:
          ma(1n+p, acc)

# d: a cycle head whose turn holds a call fixed for the cycle
@unsafe
def ha(i: Nat, +k: Nat, acc: Nat) -> Nat:
  match i:
    case 0n:
      acc
    case 1n+p:
      hb(p, k, Nat.add(acc, cyc(k, 0n)))

@unsafe
def hb(i: Nat, +k: Nat, acc: Nat) -> Nat:
  match i:
    case 0n:
      1n+acc
    case 1n+p:
      ha(p, k, 1n+acc)

# e: a def that calls itself and another def of its cycle, with a fixed call;
# the other def changes k on the way back
@unsafe
def hop(n: Nat, +k: Nat, acc: Nat) -> Nat:
  lp(n, False{}, 1n+k, acc)

@unsafe
def lp(n: Nat, b: Bool, +k: Nat, acc: Nat) -> Nat:
  match n:
    case 0n:
      acc
    case 1n+p:
      match b:
        case True{}:
          hop(p, k, Nat.add(acc, cyc(k, 0n)))
        case False{}:
          lp(p, True{}, k, Nat.add(acc, cyc(k, 0n)))

# f: a sum loop with two self calls (a tree) and a fixed call
def tre(+i: Nat, +k: Nat) -> Nat:
  match i:
    case 0n:
      cyc(k, 0n)
    case 1n:
      1n
    case 2n+p:
      Nat.add(Nat.add(tre(1n+p, k), cyc(k, 0n)), tre(p, k))

def show(+one: Nat) -> String:
  String.join([
    Nat.show(suma(Nat.mul(30n, one))),
    Nat.show(sumc(Nat.mul(40n, one), Nat.mul(27n, one))),
    Nat.show(ma(Nat.mul(50n, one), 0n)),
    Nat.show(mb(Nat.mul(51n, one), True{}, 0n)),
    Nat.show(ha(Nat.mul(33n, one), Nat.mul(27n, one), 0n)),
    Nat.show(hb(Nat.mul(34n, one), Nat.mul(97n, one), 0n)),
    Nat.show(hop(Nat.mul(20n, one), Nat.mul(6n, one), 0n)),
    Nat.show(lp(Nat.mul(21n, one), True{}, Nat.mul(7n, one), 0n)),
    Nat.show(tre(Nat.mul(15n, one), Nat.mul(27n, one))),
    Nat.show(suma(0n)),
    Nat.show(sumc(0n, Nat.mul(27n, one))),
    Nat.show(tre(0n, Nat.mul(9n, one)))], "\n")

def main() -> IO(Unit):
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(show(List.length(&1, String, xs)))

#|441
#|4440
#|141
#|153
#|1904
#|2024
#|228
#|236
#|151903
#|0
#|0
#|19
