# #2154 x #2149 / #2188 / #2175 / #2180: lanes in a loop that has a mask-free copy,
# over an inner loop that is a tail cycle or a sum loop, inside a sum loop, and in
# a loop with a fixed call.
import Base

def mix(n: Nat, +k: U32, +x: U32) -> U32:
  match n:
    case 0n:
      x
    case 1n+p:
      mix(p, k, U32.add(U32.mul(U32.xor(x, k), 2654435761), U32.shrn(x, 7n)))

# a: the outer loop writes an Array at a bounded index (two copies, #2149)
def fillmix(+j: Nat, +n: Nat, a: Array<U32>) -> Array<U32>:
  match j:
    case 0n:
      a
    case 1n+p:
      fillmix(p, n, Array.set(U32, a, U32.from_nat(p), mix(n, 5, U32.from_nat(p))))

def asum(+j: Nat, w: Array<U32> & U32, acc: U32) -> U32:
  match j:
    case 0n:
      (a, v) = w
      U32.add(acc, v)
    case 1n+p:
      (a, v) = w
      asum(p, Array.get(U32, a, U32.from_nat(p)), U32.add(U32.mul(acc, 31), v))

def arr(+j: Nat, +n: Nat, +size: Nat) -> U32:
  asum(j, Array.get(U32, fillmix(j, n, Array.new(U32, size, 1)), 0), 0)

# b: the inner loop is a tail cycle of two defs (#2188)
@unsafe
def ca(n: Nat, +k: U32, +x: U32) -> U32:
  match n:
    case 0n:
      x
    case 1n+p:
      cb(p, k, U32.add(U32.mul(x, 3), k))

@unsafe
def cb(n: Nat, +k: U32, +x: U32) -> U32:
  ca(n, k, U32.xor(x, U32.shrn(x, 3n)))

def sum_cyc(+j: Nat, +n: Nat, acc: U32) -> U32:
  match j:
    case 0n:
      acc
    case 1n+p:
      sum_cyc(p, n, U32.add(U32.mul(acc, 31), ca(n, 7, U32.from_nat(p))))

# c: the inner loop is a sum loop (#2175)
def tsum(+n: Nat, +x: U32) -> U32:
  match n:
    case 0n:
      x
    case 1n+p:
      U32.add(U32.mul(U32.from_nat(n), x), tsum(p, x))

def sum_acc(+j: Nat, +n: Nat, acc: U32) -> U32:
  match j:
    case 0n:
      acc
    case 1n+p:
      sum_acc(p, n, U32.add(U32.mul(acc, 31), tsum(n, U32.from_nat(p))))

# d: the outer loop is a sum loop
def osum(+j: Nat, +n: Nat) -> U32:
  match j:
    case 0n:
      0
    case 1n+p:
      U32.add(mix(n, 5, U32.from_nat(p)), osum(p, n))

# e: the outer loop has a call fixed for it (#2180)
def fx(+j: Nat, +n: Nat, +k: Nat, acc: U32) -> U32:
  match j:
    case 0n:
      acc
    case 1n+p:
      fx(p, n, k, U32.add(U32.mul(acc, 31), U32.add(mix(n, 5, U32.from_nat(p)), mix(k, 9, 3))))

def show(+one: Nat) -> String:
  +j = Nat.mul(40n, one)
  +n = Nat.mul(12n, one)
  String.join([
    U32.show(arr(j, n, Nat.mul(6n, one))),
    U32.show(arr(j, n, Nat.mul(4n, one))),
    U32.show(arr(Nat.mul(7n, one), n, Nat.mul(3n, one))),
    U32.show(arr(j, Nat.mul(3n, one), Nat.mul(6n, one))),
    U32.show(sum_cyc(j, n, 0)),
    U32.show(sum_cyc(j, Nat.mul(2n, one), 1)),
    U32.show(sum_acc(j, n, 0)),
    U32.show(sum_acc(Nat.mul(5n, one), n, 2)),
    U32.show(osum(j, n)),
    U32.show(osum(Nat.mul(17n, one), Nat.mul(9n, one))),
    U32.show(fx(j, n, Nat.mul(11n, one), 0)),
    U32.show(fx(0n, n, Nat.mul(11n, one), 4))], "\n")

def main() -> IO(Unit):
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(show(List.length(&1, String, xs)))

#|1364984499
#|2892548374
#|4286810443
#|8912476
#|3932962953
#|2618358468
#|3255375956
#|356305692
#|2682308607
#|1940557371
#|3585613659
#|4
