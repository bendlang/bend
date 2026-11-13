# A countdown loop that calls a countdown loop over words each turn runs the
# next turns' calls side by side on the host. Every shape here must print
# what one call a turn prints: turns under, at and past the lane count; an
# inner count of zero, under and at the least the lanes take, and one written
# as a literal; an inner count that differs by turn, or agrees only inside a
# block of turns; an inner loop that leaves early for some turns or has a
# third row; a callee that is the loop itself or reaches it through a helper;
# a result of two words; F32 state; a countdown that is not the first
# parameter; an argument that changes between turns; an outer loop with a
# third row or a second countdown; and a loop that leaves before its last
# turn. The counts come back through a join, so clang cannot know them.
import Base

type Two is Data:
  Two{a: U32, b: U32}

def mix(n: Nat, +k: U32, +x: U32) -> U32:
  match n:
    case 0n:
      x
    case 1n+p:
      mix(p, k, U32.add(U32.mul(U32.xor(x, k), 2654435761), U32.shrn(x, 7n)))

def seed(+i: U32, n: Nat) -> U32:
  mix(n, U32.add(i, 17), U32.mul(i, 40503))

# through a helper, the count fixed for the loop
def sum_help(+j: Nat, +n: Nat, acc: U32) -> U32:
  match j:
    case 0n:
      acc
    case 1n+p:
      sum_help(p, n, U32.add(U32.mul(acc, 31), seed(U32.from_nat(p), n)))

# the loop called as it is
def sum_self(+j: Nat, +n: Nat, acc: U32) -> U32:
  match j:
    case 0n:
      acc
    case 1n+p:
      sum_self(p, n, U32.add(U32.mul(acc, 31), mix(n, 5, U32.from_nat(p))))

# the inner count is the turn's own
def sum_tri(+j: Nat, acc: U32) -> U32:
  match j:
    case 0n:
      acc
    case 1n+p:
      sum_tri(p, U32.add(U32.mul(acc, 31), mix(p, 9, 3)))

# the inner loop leaves at once when its flag is set
def gate(f: Bool, n: Nat, +x: U32) -> U32:
  match f n:
    case True{} m:
      U32.add(x, 1000)
    case False{} 0n:
      x
    case False{} 1n+p:
      gate(False{}, p, U32.add(U32.mul(x, 3), 1))

def sum_gate(+j: Nat, +n: Nat, acc: U32) -> U32:
  match j:
    case 0n:
      acc
    case 1n+p:
      sum_gate(p, n, U32.add(U32.mul(acc, 31), gate(U32.is_zero(U32.and(U32.from_nat(p), 3)), n, U32.from_nat(p))))

# two words out
def pair(n: Nat, +a: U32, +b: U32) -> Two:
  match n:
    case 0n:
      Two{a, b}
    case 1n+p:
      pair(p, U32.add(a, b), U32.xor(U32.mul(b, 5), a))

def two_sum(t: Two) -> U32:
  match t:
    case Two{a, b}:
      U32.add(U32.mul(a, 7), b)

def sum_pair(+j: Nat, +n: Nat, acc: U32) -> U32:
  match j:
    case 0n:
      acc
    case 1n+p:
      sum_pair(p, n, U32.add(U32.mul(acc, 31), two_sum(pair(n, U32.from_nat(p), 3))))

# F32 state
def decay(n: Nat, x: F32, +r: F32) -> F32:
  match n:
    case 0n:
      x
    case 1n+p:
      decay(p, F32.add(F32.mul(x, r), F32.div(r, U32.to_f32(3))), r)

def sum_f32(+j: Nat, +n: Nat, acc: F32) -> F32:
  match j:
    case 0n:
      acc
    case 1n+p:
      sum_f32(p, n, F32.add(acc, decay(n, U32.to_f32(U32.from_nat(p)), F32.div(U32.to_f32(7), U32.to_f32(8)))))

# an argument that changes between turns
def sum_var(+j: Nat, +n: Nat, +k: U32, acc: U32) -> U32:
  match j:
    case 0n:
      acc
    case 1n+p:
      sum_var(p, n, U32.add(U32.mul(k, 3), 1), U32.add(U32.mul(acc, 31), mix(n, k, U32.from_nat(p))))

# leaves before its last turn
def find(+j: Nat, hit: Bool, +n: Nat, +want: U32, +last: U32) -> U32:
  match j hit:
    case 0n True{}:
      last
    case 0n False{}:
      4294967295
    case 1n+p True{}:
      last
    case 1n+p False{}:
      +v = mix(n, 5, U32.from_nat(p))
      find(p, U32.is_eq(U32.and(v, 15), want), n, want, U32.from_nat(p))

# the predecessor's count twice in a turn
def sum_both(+j: Nat, +n: Nat, acc: U32) -> U32:
  match j:
    case 0n:
      acc
    case 1n+p:
      sum_both(p, n, U32.add(U32.mul(acc, 31), U32.xor(seed(U32.from_nat(p), n), mix(n, 11, U32.mul(U32.from_nat(p), 3)))))

# the countdown is not the first parameter, and a fixed record rides along
def late(+t: Two, +j: Nat, +n: Nat, acc: U32) -> U32:
  match t j:
    case Two{a, b} 0n:
      acc
    case Two{a, b} 1n+p:
      late(Two{a, b}, p, n, U32.add(U32.mul(acc, 31), mix(n, a, U32.add(b, U32.from_nat(p)))))

# the inner count is the turn's own, equal inside a block of 16 turns
def blocks(+j: Nat, acc: U32) -> U32:
  match j:
    case 0n:
      acc
    case 1n+p:
      blocks(p, U32.add(U32.mul(acc, 31), mix(U32.to_nat(U32.add(U32.shrn(U32.from_nat(p), 4n), 8)), 7, U32.from_nat(p))))

# the inner count alternates between turns
def alt(+j: Nat, acc: U32) -> U32:
  match j:
    case 0n:
      acc
    case 1n+p:
      alt(p, U32.add(U32.mul(acc, 31), mix(U32.to_nat(U32.add(U32.and(U32.from_nat(p), 1), 8)), 7, U32.from_nat(p))))

# an inner loop with three rows
def three(n: Nat, +x: U32) -> U32:
  match n:
    case 0n:
      x
    case 1n:
      U32.add(x, 5)
    case 2n+p:
      three(1n+p, U32.mul(x, 3))

def sum3(+j: Nat, +n: Nat, acc: U32) -> U32:
  match j:
    case 0n:
      acc
    case 1n+p:
      sum3(p, n, U32.add(U32.mul(acc, 31), three(n, U32.from_nat(p))))

# an outer loop with three rows
def out3(+j: Nat, +n: Nat, acc: U32) -> U32:
  match j:
    case 0n:
      acc
    case 1n:
      U32.add(acc, mix(n, 3, 1))
    case 2n+p:
      out3(1n+p, n, U32.add(U32.mul(acc, 31), mix(n, 3, U32.from_nat(p))))

# two countdowns in the outer loop
def grid(+i: Nat, +j: Nat, +w: Nat, +n: Nat, acc: U32) -> U32:
  match i j:
    case 0n k:
      acc
    case 1n+p 0n:
      grid(p, w, w, n, U32.mul(acc, 7))
    case 1n+p 1n+q:
      grid(1n+p, q, w, n, U32.add(U32.mul(acc, 31), mix(n, U32.from_nat(p), U32.from_nat(q))))

# the inner loop's count is huge and its step cheap; the zero row does work
def tail(n: Nat, +x: U32, +k: U32) -> U32:
  match n:
    case 0n:
      mix(3n, k, x)
    case 1n+p:
      tail(p, U32.add(x, k), k)

def sumt(+j: Nat, +n: Nat, acc: U32) -> U32:
  match j:
    case 0n:
      acc
    case 1n+p:
      sumt(p, n, U32.add(U32.mul(acc, 31), tail(n, U32.from_nat(p), 3)))

# a count clang cannot know: it comes back through a join
def hide.id(n: Nat) -> Nat:
  n

def hide(n: Nat) -> Nat:
  a b = hide.id(n) hide.id(0n)
  Nat.add(a, b)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(sum_help(hide(0n), hide(9n), 1)))
    IO.print(U32.show(sum_help(hide(5n), hide(9n), 1)))
    IO.print(U32.show(sum_help(hide(15n), hide(9n), 1)))
    IO.print(U32.show(sum_help(hide(16n), hide(9n), 1)))
    IO.print(U32.show(sum_help(hide(17n), hide(9n), 1)))
    IO.print(U32.show(sum_help(hide(31n), hide(9n), 1)))
    IO.print(U32.show(sum_help(hide(32n), hide(9n), 1)))
    IO.print(U32.show(sum_help(100n, hide(9n), 1)))
    IO.print(U32.show(sum_help(100n, hide(0n), 1)))
    IO.print(U32.show(sum_help(100n, hide(1n), 1)))
    IO.print(U32.show(sum_help(100n, hide(7n), 1)))
    IO.print(U32.show(sum_help(100n, hide(8n), 1)))
    IO.print(U32.show(sum_help(100n, 9n, 1)))
    IO.print(U32.show(sum_self(100n, hide(9n), 1)))
    IO.print(U32.show(sum_self(hide(16n), hide(0n), 1)))
    IO.print(U32.show(sum_tri(hide(100n), 1)))
    IO.print(U32.show(sum_gate(100n, hide(12n), 1)))
    IO.print(U32.show(sum_gate(hide(33n), hide(0n), 1)))
    IO.print(U32.show(sum_pair(100n, hide(12n), 1)))
    IO.print(F32.show(sum_f32(100n, hide(12n), U32.to_f32(0))))
    IO.print(U32.show(sum_var(100n, hide(12n), 2, 1)))
    IO.print(U32.show(find(100n, False{}, hide(12n), 3, 0)))
    IO.print(U32.show(find(100n, False{}, hide(12n), 16, 0)))
    IO.print(U32.show(sum_both(100n, hide(10n), 1)))
    IO.print(U32.show(late(Two{5, 9}, 100n, hide(12n), 1)))
    IO.print(U32.show(late(Two{5, 9}, 16n, hide(0n), 1)))
    IO.print(U32.show(blocks(hide(96n), 1)))
    IO.print(U32.show(blocks(hide(100n), 1)))
    IO.print(U32.show(alt(hide(100n), 1)))
    IO.print(U32.show(sum3(100n, hide(12n), 1)))
    IO.print(U32.show(sum3(100n, hide(1n), 1)))
    IO.print(U32.show(out3(100n, hide(12n), 1)))
    IO.print(U32.show(grid(40n, 37n, 37n, hide(9n), 1)))
    IO.print(U32.show(sumt(100n, hide(100000n), 1)))

#|1
#|3497085407
#|3195285350
#|2480114000
#|1090971253
#|4121641184
#|1695842554
#|1063578868
#|815542275
#|1170696684
#|3119507878
#|558410580
#|1063578868
#|2297106086
#|2486590713
#|3826271134
#|1472681631
#|124138839
#|3898200705
#|1183.352
#|2981024643
#|51
#|4294967295
#|1033024669
#|4259390814
#|3751577081
#|2928727192
#|1780888808
#|1470578759
#|2567942651
#|600928591
#|3408042983
#|2854013888
#|646768023
