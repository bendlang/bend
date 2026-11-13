# loops whose accesses sit in helper defs, or run to the array's last cell:
# each shape in range (the copy without the masks runs) and out of it
import Base

# a count the compiler cannot read: no loop here is unrolled
def zero(r: Array<U32> & U32) -> U32:
  (a, x) = r
  x

def nat(+k: U32) -> Nat:
  U32.to_nat((k + zero(Array.get(U32, [0 : U32*1n], 0)) : U32))

# r is a[j]: n more reads follow it, at j + 1, j + 2, ..
def fold(n: Nat, +j: U32, acc: U32, r: Array<U32> & U32) -> U32:
  match n:
    case 0n:
      (a, x) = r
      (acc * 31 + x : U32)
    case 1n+p:
      (a, x) = r
      +q = (j + 1 : U32)
      fold(p, q, (acc * 31 + x : U32), a[q])

def sum(a: Array<U32>) -> U32:
  fold(nat(15), 0, 0, a[0])

# n cells from i: the last index is i + n - 1
def put(n: Nat, +i: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      put(p, (i + 1 : U32), a[i] <- (i * 7 + 3 : U32))

# n + 1 cells from i: the zero arm writes too, at i + n
def put1(n: Nat, +i: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a[i] <- (i * 5 + 1 : U32)
    case 1n+p:
      put1(p, (i + 1 : U32), a[i] <- (i * 5 + 1 : U32))

# two off the countdown a step, one cell: the arm of one writes too
def two(n: Nat, +i: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n:
      a[i] <- 77
    case 2n+p:
      two(p, (i + 2 : U32), a[(i + 1 : U32)] <- (i + 9 : U32))

# two countdowns: the first bounds the counter
def duo(m: Nat, n: Nat, +i: U32, a: Array<U32>) -> Array<U32>:
  match m:
    case 0n:
      a
    case 1n+pm:
      match n:
        case 0n:
          a
        case 1n+pn:
          duo(pm, pn, (i + 1 : U32), a[i] <- (i * 3 + 2 : U32))

# a[i] <- a[i] * 3 + i through a helper
def upd.at(+i: U32, r: Array<U32> & U32) -> Array<U32>:
  (a, +x) = r
  a[i] <- (x * 3 + i : U32)

def upd(n: Nat, +i: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      upd(p, (i + 1 : U32), upd.at(i, a[i]))

# the helper writes the second array, the loop the first
def set2(+i: U32, +v: U32, b: Array<U32>) -> Array<U32>:
  b[i] <- v

def both(n: Nat, +i: U32, a: Array<U32>, b: Array<U32>) -> U32:
  match n:
    case 0n:
      (sum(a) * 17 + sum(b) : U32)
    case 1n+p:
      both(p, (i + 1 : U32), a[i] <- (i + 1 : U32), set2(i, (i * 9 + 4 : U32), b))

# the helper hands the two arrays back swapped
type Two is Type:
  Two{a: Array<U32>, b: Array<U32>}

def flip.at(+i: U32, b: Array<U32>, a: Array<U32>) -> Two:
  Two{b, a[i] <- (i * 11 + 5 : U32)}

def flip(n: Nat, +i: U32, t: Two) -> U32:
  match n:
    case 0n:
      Two{a, b} = t
      (sum(a) * 17 + sum(b) : U32)
    case 1n+p:
      Two{a, b} = t
      flip(p, (i + 1 : U32), flip.at(i, b, a))

# the helper picks which array it hands back
def pick.at(c: Bool, +i: U32, a: Array<U32>, b: Array<U32>) -> Two:
  match c:
    case True{}:
      Two{a[i] <- (i + 40 : U32), b}
    case False{}:
      Two{b, a[i] <- (i + 50 : U32)}

def pick(n: Nat, +i: U32, t: Two) -> U32:
  match n:
    case 0n:
      Two{a, b} = t
      (sum(a) * 17 + sum(b) : U32)
    case 1n+p:
      Two{a, b} = t
      pick(p, (i + 1 : U32), pick.at(U32.is_lt((i % 3 : U32), 2), i, a, b))

# the helper answers a new array on some steps
def fresh.at(c: Bool, +i: U32, a: Array<U32>) -> Array<U32>:
  match c:
    case True{}:
      a[i] <- (i + 60 : U32)
    case False{}:
      [i : U32*4n]

def fresh(n: Nat, +i: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      fresh(p, (i + 1 : U32), fresh.at(U32.is_ne(i, 9), i, a))

# a record of arrays through a chain of helpers, as a row of a table
type Dp is Type:
  Dp{b: Array<U32>, prev: Array<U32>, cur: Array<U32>}

def cell.f3(+j: U32, x: U32, up: U32, b: Array<U32>, prev: Array<U32>, r: Array<U32> & U32) -> Dp:
  (cur, left) = r
  Dp{b, prev, cur[(j + 1 : U32)] <- (x + up * 3 + left * 5 : U32)}

def cell.f2(+j: U32, x: U32, b: Array<U32>, cur: Array<U32>, r: Array<U32> & U32) -> Dp:
  (prev, up) = r
  cell.f3(j, x, up, b, prev, Array.get(U32, cur, j))

def cell.f1(+j: U32, prev: Array<U32>, cur: Array<U32>, r: Array<U32> & U32) -> Dp:
  (b, x) = r
  cell.f2(j, x, b, cur, Array.get(U32, prev, (j + 1 : U32)))

def cell(+j: U32, st: Dp) -> Dp:
  Dp{b, prev, cur} = st
  cell.f1(j, prev, cur, Array.get(U32, b, j))

def row(n: Nat, +j: U32, st: Dp) -> U32:
  match n:
    case 0n:
      Dp{b, prev, cur} = st
      ((sum(b) * 17 + sum(prev)) * 17 + sum(cur) : U32)
    case 1n+q:
      row(q, (j + 1 : U32), cell(j, st))

# one helper twice in a step, the inner call far out of range
def far.at(+i: U32, +v: U32, a: Array<U32>) -> Array<U32>:
  a[i] <- v

def far(n: Nat, +i: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      far(p, (i + 1 : U32), far.at(i, (i + 1 : U32), far.at((i + 100 : U32), 7, a)))

# an index read from the array and clamped, in a helper
def hop.at(+k: U32, r: Array<U32> & U32) -> Array<U32>:
  (a, +x) = r
  a[U32.min(x, k)] <- (x + 1 : U32)

def hop(n: Nat, +i: U32, +k: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      hop(p, (i + 1 : U32), k, hop.at(k, a[i]))

# the helper's one-word result bound by a let, then read
def let.go(n: Nat, +i: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      b = far.at(i, (i * 2 : U32), a)
      let.go(p, (i + 1 : U32), b[(i + 1 : U32)] <- 5)

def one(a: Array<U32>) -> U32:
  fold(nat(3), 0, 0, a[0])

# boxes: chains in the cells, a chain lent to the helper and one it consumes,
# and more helper calls in a step than are emitted in place

type Chain is Data:
  CNil{}
  CCons{k: U32, t: Chain}

def len(c: Chain, acc: U32) -> U32:
  match c:
    case CNil{}:
      acc
    case CCons{h, t}:
      len(t, U32.inc(acc))

def csum(c: Chain, acc: U32) -> U32:
  match c:
    case CNil{}:
      acc
    case CCons{h, t}:
      csum(t, (acc * 7 + h : U32))

# a cons onto the chain at b, through two helpers
def ins.put(a: Array<Chain>, +b: U32, k: U32, c: Chain, keep: Bool) -> Array<Chain>:
  match keep:
    case True{}:
      a
    case False{}:
      Array.set(Chain, a, b, CCons{k, c})

def ins(+b: U32, +k: U32, r: Array<Chain> & Chain) -> Array<Chain>:
  (a, +c0) = r
  ins.put(a, b, k, c0, U32.is_gt(len(c0, 0), 5))

def fill(n: Nat, +j: U32, +m: U32, a: Array<Chain>) -> Array<Chain>:
  match n:
    case 0n:
      a
    case 1n+p:
      +b = (j * 5 .&. m : U32)
      fill(p, U32.inc(j), m, ins(b, (j * 3 + 1 : U32), Array.get(Chain, a, b)))

def mix(+i: U32, acc: U32, r: Array<Chain> & Chain) -> Array<Chain> & U32:
  (a, c) = r
  (a, (acc * 31 + csum(c, i) : U32))

def sweep(n: Nat, +i: U32, r: Array<Chain> & U32) -> U32:
  match n:
    case 0n:
      (a, acc) = r
      acc
    case 1n+p:
      (a, acc) = r
      sweep(p, U32.inc(i), mix(i, acc, Array.get(Chain, a, i)))

# a chain the helper only reads, lent again each step
def head(c: Chain) -> U32:
  match c:
    case CNil{}:
      0
    case CCons{h, t}:
      h

def lend.at(+i: U32, +xs: Chain, a: Array<U32>) -> Array<U32>:
  a[i] <- (head(xs) + i : U32)

def lend(n: Nat, +i: U32, +xs: Chain, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      lend(p, (i + 1 : U32), xs, lend.at(i, xs, a))

# a chain the helper consumes, built each step
def eat.at(+i: U32, xs: Chain, a: Array<U32>) -> Array<U32>:
  a[i] <- (len(xs, 0) + i : U32)

def eat(n: Nat, +i: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      eat(p, (i + 1 : U32), eat.at(i, CCons{i, CCons{2, CNil{}}}, a))

# forty helper calls in a step: more than are emitted in place
def w(+i: U32, a: Array<U32>) -> Array<U32>:
  a[i] <- (i + 1 : U32)

def many(n: Nat, +i: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      many(p, (i + 1 : U32),
        w(i, w(i, w(i, w(i, w(i, w(i, w(i, w(i, w(i, w(i,
        w(i, w(i, w(i, w(i, w(i, w(i, w(i, w(i, w(i, w(i,
        w(i, w(i, w(i, w(i, w(i, w(i, w(i, w(i, w(i, w(i,
        w(i, w(i, w(i, w(i, w(i, w(i, w(i, w(i, w(i, w((i + 1 : U32), a)))))))))))))))))))))))))))))))))))))))))

def main() -> IO(Unit):
  do IO<Unit>:
    # to the last cell, one past it, and from 1
    IO.print(U32.show(sum(put(nat(16), 0, [0 : U32*16n]))))
    IO.print(U32.show(sum(put(nat(17), 0, [0 : U32*16n]))))
    IO.print(U32.show(sum(put(nat(16), 1, [0 : U32*16n]))))
    IO.print(U32.show(sum(put(nat(40), 5, [0 : U32*16n]))))
    # an array of one cell
    IO.print(U32.show(one(put(nat(1), 0, [0 : U32*1n]))))
    IO.print(U32.show(one(put(nat(3), 0, [0 : U32*1n]))))
    IO.print(U32.show(one(upd(nat(1), 0, put(nat(1), 0, [0 : U32*1n])))))
    IO.print(U32.show(one(upd(nat(3), 0, put(nat(1), 0, [0 : U32*1n])))))
    # the zero arm's write is one further
    IO.print(U32.show(sum(put1(nat(15), 0, [0 : U32*16n]))))
    IO.print(U32.show(sum(put1(nat(16), 0, [0 : U32*16n]))))
    # two a step
    IO.print(U32.show(sum(two(nat(16), 0, [0 : U32*64n]))))
    IO.print(U32.show(sum(two(nat(17), 0, [0 : U32*32n]))))
    IO.print(U32.show(sum(two(nat(16), 0, [0 : U32*16n]))))
    IO.print(U32.show(sum(two(nat(34), 0, [0 : U32*16n]))))
    IO.print(U32.show(sum(two(nat(17), 14, [0 : U32*16n]))))
    # two countdowns
    IO.print(U32.show(sum(duo(nat(16), 16n, 0, [0 : U32*16n]))))
    IO.print(U32.show(sum(duo(nat(16), 40n, 0, [0 : U32*16n]))))
    IO.print(U32.show(sum(duo(nat(40), 16n, 0, [0 : U32*16n]))))
    IO.print(U32.show(sum(duo(nat(40), 40n, 3, [0 : U32*16n]))))
    # the helper's update, in range and around
    IO.print(U32.show(sum(upd(nat(16), 0, put(nat(16), 0, [0 : U32*16n])))))
    IO.print(U32.show(sum(upd(nat(17), 0, put(nat(16), 0, [0 : U32*16n])))))
    IO.print(U32.show(sum(upd(nat(16), 9, put(nat(16), 0, [0 : U32*16n])))))
    # the second array is the small one
    IO.print(U32.show(both(nat(16), 0, [0 : U32*16n], [0 : U32*16n])))
    IO.print(U32.show(both(nat(16), 0, [0 : U32*16n], [0 : U32*4n])))
    IO.print(U32.show(both(nat(16), 0, [0 : U32*4n], [0 : U32*16n])))
    # swapped, picked, fresh
    IO.print(U32.show(flip(nat(16), 0, Two{[0 : U32*16n], [0 : U32*4n]})))
    IO.print(U32.show(flip(nat(16), 0, Two{[0 : U32*16n], [0 : U32*16n]})))
    IO.print(U32.show(pick(nat(16), 0, Two{[0 : U32*16n], [0 : U32*4n]})))
    IO.print(U32.show(pick(nat(16), 0, Two{[0 : U32*4n], [0 : U32*16n]})))
    IO.print(U32.show(sum(fresh(nat(16), 0, [0 : U32*16n]))))
    IO.print(U32.show(sum(fresh(nat(9), 0, [0 : U32*16n]))))
    # the row: cur and prev one cell longer than the row, then not
    IO.print(U32.show(row(nat(15), 0, Dp{put(nat(16), 0, [0 : U32*16n]), put(nat(16), 3, [0 : U32*16n]), [1 : U32*16n]})))
    IO.print(U32.show(row(nat(16), 0, Dp{put(nat(16), 0, [0 : U32*16n]), put(nat(16), 3, [0 : U32*16n]), [1 : U32*16n]})))
    IO.print(U32.show(row(nat(8), 0, Dp{put(nat(16), 0, [0 : U32*16n]), put(nat(16), 3, [0 : U32*8n]), [1 : U32*16n]})))
    IO.print(U32.show(row(nat(8), 0, Dp{put(nat(4), 0, [0 : U32*4n]), put(nat(16), 3, [0 : U32*16n]), [1 : U32*16n]})))
    IO.print(U32.show(row(nat(8), 0, Dp{put(nat(16), 0, [0 : U32*16n]), put(nat(16), 3, [0 : U32*16n]), [1 : U32*8n]})))
    # twice in a step
    IO.print(U32.show(sum(far(nat(16), 0, [0 : U32*16n]))))
    IO.print(U32.show(sum(far(nat(5), 0, [0 : U32*128n]))))
    # a clamp that fits, and one that does not
    IO.print(U32.show(sum(hop(nat(16), 0, 15, put(nat(16), 0, [0 : U32*16n])))))
    IO.print(U32.show(sum(hop(nat(16), 0, 99, put(nat(16), 0, [0 : U32*16n])))))
    # a let
    IO.print(U32.show(sum(let.go(nat(15), 0, [0 : U32*16n]))))
    IO.print(U32.show(sum(let.go(nat(16), 0, [0 : U32*16n]))))
    # chains in the cells; a chain lent, and consumed; forty helpers
    IO.print(U32.show(sweep(nat(16), 0, (fill(nat(200), 0, 15, [CNil{} : Chain*16n]), 0))))
    IO.print(U32.show(sweep(nat(40), 3, (fill(nat(200), 0, 31, [CNil{} : Chain*16n]), 0))))
    IO.print(U32.show(sweep(nat(16), 0, (fill(nat(9), 0, 7, [CNil{} : Chain*16n]), 0))))
    IO.print(U32.show(sum(lend(nat(16), 0, CCons{5, CCons{6, CNil{}}}, [0 : U32*16n]))))
    IO.print(U32.show(sum(lend(nat(20), 0, CCons{5, CCons{6, CNil{}}}, [0 : U32*16n]))))
    IO.print(U32.show(sum(eat(nat(16), 0, [0 : U32*16n]))))
    IO.print(U32.show(sum(eat(nat(20), 0, [0 : U32*16n]))))
    IO.print(U32.show(sum(many(nat(15), 0, [0 : U32*16n]))))
    IO.print(U32.show(sum(many(nat(16), 0, [0 : U32*16n]))))

#|2951902008
#|1606649032
#|1606649032
#|1030594760
#|92352
#|523328
#|277056
#|2647424
#|1197953320
#|3304892120
#|743282048
#|743282048
#|743282048
#|834849296
#|2483826499
#|1297322520
#|1297322520
#|1297322520
#|428146152
#|4104112560
#|3925819726
#|2178391968
#|1100944848
#|4197813200
#|2178399184
#|3241923688
#|812112984
#|3596727165
#|946152249
#|3071308296
#|3364920640
#|2818331896
#|3901368136
#|3817483588
#|2268317588
#|1331086392
#|301601158
#|459695133
#|2691016065
#|3308984762
#|3381714935
#|829044075
#|1384760008
#|2362673524
#|915772445
#|4063892744
#|2937821448
#|2210574856
#|1084503560
#|3024457992
#|3445845752
