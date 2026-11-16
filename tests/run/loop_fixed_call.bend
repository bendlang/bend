# A def that calls itself computes a call once when the call reads only
# parameters every self call passes back as they are: the arm that holds it
# binds it and goes on in a copy of the def that carries the value. Every
# count comes from the command line's length (1 in the harness), which no
# compiler sees. The shapes: a counted loop; a loop that never turns around a
# call that would stop the program; the call in one arm of two, reached late,
# and never (it would stop the program); a parameter one self call passes
# back and another changes, which is not fixed; an inner loop whose call
# reads the outer loop's counter; one def called on two fixed parameters,
# whose values must not mix; a recursion that is no tail call, and one that
# forks; calls no arm evaluates (an unused let, a lambda and a partial
# application never applied); the call bound by a let and written again in
# the exit arm; results of two words and of a Bool; a name bound again
# before the call; and an Array an @unsafe loop writes through one handle
# and reads through the one it passes back, which is not fixed either.
import Base

def tri(+n: Nat, acc: Nat) -> Nat:
  match n:
    case 0n:
      acc
    case 1n+p:
      tri(p, Nat.add(acc, n))

def boom(+n: Nat, acc: Nat) -> Nat:
  match n:
    case 0n:
      acc
    case 1n+p:
      boom(p, Nat.mul(Nat.mul(acc, 65536n), Nat.mul(65536n, 65536n)))

def plain(+i: Nat, +k: Nat, acc: Nat) -> Nat:
  match i:
    case 0n:
      acc
    case 1n+p:
      plain(p, k, Nat.add(acc, tri(k, 0n)))

def stop(+i: Nat, +k: Nat, acc: Nat) -> Nat:
  match i:
    case 0n:
      acc
    case 1n+p:
      stop(p, k, Nat.add(acc, boom(k, 1n)))

def late(+i: Nat, f: Bool, +k: Nat, acc: Nat) -> Nat:
  match i:
    case 0n:
      acc
    case 1n+p:
      match f:
        case True{}:
          late(p, Nat.is_lt(p, 4n), k, Nat.add(acc, tri(k, 0n)))
        case False{}:
          late(p, Nat.is_lt(p, 4n), k, Nat.add(acc, 1n))

def never(+i: Nat, f: Bool, +k: Nat, acc: Nat) -> Nat:
  match i:
    case 0n:
      acc
    case 1n+p:
      match f:
        case True{}:
          never(p, Nat.is_lt(1000n, p), k, Nat.add(acc, boom(k, 1n)))
        case False{}:
          never(p, Nat.is_lt(1000n, p), k, Nat.add(acc, 1n))

def moved(+i: Nat, f: Bool, +k: Nat, acc: Nat) -> Nat:
  match i:
    case 0n:
      acc
    case 1n+p:
      match f:
        case True{}:
          moved(p, False{}, k, Nat.add(acc, tri(k, 0n)))
        case False{}:
          moved(p, True{}, Nat.add(k, 1n), acc)

def inner(+j: Nat, +k: Nat, acc: Nat) -> Nat:
  match j:
    case 0n:
      acc
    case 1n+q:
      inner(q, k, Nat.add(acc, tri(k, 0n)))

def outer(+i: Nat, +m: Nat, acc: Nat) -> Nat:
  match i:
    case 0n:
      acc
    case 1n+p:
      outer(p, m, inner(m, i, acc))

def two(+i: Nat, f: Bool, +a: Nat, +b: Nat, acc: Nat) -> Nat:
  match i:
    case 0n:
      Nat.add(acc, tri(b, 0n))
    case 1n+p:
      match f:
        case True{}:
          two(p, False{}, a, b, Nat.add(acc, tri(a, 0n)))
        case False{}:
          two(p, True{}, a, b, Nat.add(Nat.add(acc, tri(b, 0n)), tri(a, 0n)))

def back(+n: Nat, +k: Nat) -> Nat:
  match n:
    case 0n:
      0n
    case 1n+p:
      Nat.add(back(p, k), tri(k, 0n))

def walk(+d: Nat, +k: Nat) -> Nat:
  match d:
    case 0n:
      1n
    case 1n+e:
      a b = walk(e, k) walk(e, k)
      Nat.add(tri(k, 0n), Nat.add(a, b))

def use(f: Nat -> Nat, +on: Bool, x: Nat) -> Nat:
  match on:
    case True{}:
      f(x)
    case False{}:
      x

def add3(a: Nat, b: Nat, c: Nat) -> Nat:
  Nat.add(a, Nat.add(b, c))

def unused(+i: Nat, +k: Nat, acc: Nat) -> Nat:
  match i:
    case 0n:
      acc
    case 1n+p:
      dead = boom(k, 1n)
      x = use(y => Nat.add(y, boom(k, 2n)), Nat.is_lt(k, 1n), acc)
      unused(p, k, use(add3(boom(k, 3n), 1n), Nat.is_lt(k, 1n), Nat.add(x, 5n)))

def twice(+i: Nat, +k: Nat, acc: Nat) -> Nat:
  match i:
    case 0n:
      Nat.add(acc, Nat.add(tri(k, 0n), tri(Nat.add(k, 1n), 0n)))
    case 1n+p:
      +x = tri(k, 0n)
      y = Nat.add(x, tri(k, 0n))
      twice(p, k, Nat.add(Nat.add(acc, x), Nat.add(y, tri(Nat.add(k, 1n), 0n))))

type Two is Data:
  Two{a: U32, b: Nat}

def pair(+n: Nat, a: U32, b: Nat) -> Two:
  match n:
    case 0n:
      Two{a, b}
    case 1n+p:
      pair(p, U32.add(a, 3), Nat.add(b, n))

def odd(+n: Nat, o: Bool) -> Bool:
  match n:
    case 0n:
      o
    case 1n+p:
      odd(p, Bool.not(o))

def sum2(t: Two, o: Bool, acc: Nat) -> Nat:
  match t:
    case Two{a, b}:
      match o:
        case True{}:
          Nat.add(acc, Nat.add(U32.to_nat(a), b))
        case False{}:
          Nat.add(acc, b)

def words(+i: Nat, +k: Nat, acc: Nat) -> Nat:
  match i:
    case 0n:
      acc
    case 1n+p:
      words(p, k, sum2(pair(k, 1, 0n), odd(k, False{}), acc))

def again(+i: Nat, +k: Nat, acc: Nat) -> Nat:
  match i:
    case 0n:
      acc
    case 1n+p:
      +k = Nat.add(k, i)
      again(p, Nat.sub(k, i), Nat.add(acc, tri(k, 0n)))

def asum(+n: Nat, w: Array<U32> & U32, acc: U32) -> U32:
  match n:
    case 0n:
      (a, v) = w
      U32.add(acc, v)
    case 1n+p:
      (a, v) = w
      asum(p, Array.get(U32, a, U32.from_nat(p)), U32.add(acc, v))

@unsafe
def wrote(+i: Nat, +a: Array<U32>, +m: Nat, acc: U32) -> U32:
  match i:
    case 0n:
      acc
    case 1n+p:
      +w = asum(0n, Array.get(U32, Array.set(U32, a, 0, U32.from_nat(i)), 0), 0)
      wrote(p, a, m, U32.add(U32.add(acc, w), asum(m, Array.get(U32, a, 0), 0)))

def show(+one: Nat) -> String:
  +t = Nat.mul(20n, one)
  +k = Nat.mul(10n, one)
  String.join([
    Nat.show(plain(t, k, 0n)),
    Nat.show(stop(Nat.sub(one, 1n), one, 7n)),
    Nat.show(late(t, False{}, Nat.mul(100n, one), 0n)),
    Nat.show(never(t, False{}, one, 0n)),
    Nat.show(moved(t, False{}, k, 0n)),
    Nat.show(outer(Nat.mul(30n, one), Nat.mul(5n, one), 0n)),
    Nat.show(two(Nat.mul(21n, one), True{}, k, Nat.mul(100n, k), 0n)),
    Nat.show(back(Nat.mul(500n, one), k)),
    Nat.show(walk(Nat.mul(8n, one), Nat.mul(7n, one))),
    Nat.show(unused(t, one, 0n)),
    Nat.show(twice(t, k, 0n)),
    Nat.show(words(t, Nat.mul(9n, one), 0n)),
    Nat.show(again(t, k, 0n)),
    U32.show(wrote(t, Array.new(U32, 3n, 1), Nat.mul(7n, one), 0))], "\n")

def main() -> IO(Unit):
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(show(List.length(&1, String, xs)))

#|1100
#|7
#|15167
#|20
#|1320
#|24800
#|5506655
#|27500
#|7396
#|100
#|4741
#|1460
#|4740
#|750
