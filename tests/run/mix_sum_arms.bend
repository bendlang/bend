# #2175 x #2177 / #2176: d~acc's returning arms (the leaf adds its value to the
# carried sum) are copied to the calls of a tree recursion. A sum that lands on
# 2^48-1 answers; U32 wraps; forks keep their own sums.
import Base

# 2^48 - 1 = 281474976710655; a full tree of depth d has 2^d leaves
def leaves(+d: Nat, +v: Nat) -> Nat:
  match d:
    case 0n:
      v
    case 1n+p:
      Nat.add(leaves(p, v), leaves(p, v))

# uneven tree: fib-shaped, leaf value v
def fibv(+n: Nat, +v: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n:
      v
    case 2n+p:
      Nat.add(fibv(1n+p, v), fibv(p, v))

def wrap(+d: Nat, +v: U32) -> U32:
  match d:
    case 0n:
      v
    case 1n+p:
      U32.add(U32.add(wrap(p, U32.mul(v, 3)), 7), wrap(p, U32.add(v, 1)))

def par(+d: Nat, +v: Nat) -> Nat:
  match d:
    case 0n:
      fibv(15n, v)
    case 1n+p:
      a b = par(p, v) par(p, 1n+v)
      Nat.add(a, Nat.add(b, leaves(3n, v)))

def show(+one: Nat) -> String:
  String.join([
    # 2^16 leaves of 4294967295 = 2^48 - 65536: under the limit
    Nat.show(leaves(Nat.mul(16n, one), 4294967295n)),
    # 2^4 leaves: 16 * 17592186044415 + 15 = 2^48 - 1 exactly when v = (2^48-16)/16
    Nat.show(Nat.add(leaves(Nat.mul(4n, one), Nat.sub(Nat.mul(Nat.mul(4194304n, one), 4194304n), 1n)), 15n)),
    Nat.show(fibv(Nat.mul(24n, one), 6069n)),
    U32.show(wrap(Nat.mul(18n, one), 3)),
    Nat.show(par(Nat.mul(6n, one), 5n)),
    Nat.show(leaves(0n, 9n))], "\n")

def main() -> IO(Unit):
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(show(List.length(&1, String, xs)))

#|281474976645120
#|281474976710655
#|281407392
#|1703929
#|315872
#|9
