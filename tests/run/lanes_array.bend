# a loop whose turns each sum a row of an array they only read, the next
# turns' sums run side by side: the sums, and the shapes that must not run so
import Base

def zero(r: Array<U32> & U32) -> U32:
  (a, x) = r
  x

# k, unknown to the compiler
def v(+k: U32) -> U32:
  (k + zero(Array.get(U32, [0 : U32*1n], 0)) : U32)

def nat(+k: U32) -> Nat:
  U32.to_nat(v(k))

def fold(n: Nat, +j: U32, acc: U32, r: Array<U32> & U32) -> U32:
  match n:
    case 0n:
      (a, x) = r
      (acc * 31 + x : U32)
    case 1n+p:
      (a, x) = r
      +q = (j + 1 : U32)
      fold(p, q, (acc * 31 + x : U32), a[q])

def hash(+m: U32, a: Array<U32>) -> U32:
  fold(U32.to_nat((m - 1 : U32)), 0, 0, a[0])

# a[i] = i * 7 + 3 for n cells from i
def fill(+n: Nat, +i: U32, a: Array<U32>) -> Array<U32>:
  match n:
    case 0n:
      a
    case 1n+p:
      fill(p, (i + 1 : U32), a[i] <- (i * 7 + 3 : U32))

# acc * 3 + a[p] + a[q] for c steps, p and q one apart each step
def madd.y(+x: U32, acc: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (a, +y) = r
  (a, (acc * 3 + x + y : U32))

def madd.x(+q: U32, acc: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (a, +x) = r
  madd.y(x, acc, a[q])

def madd(+p: U32, +q: U32, s: Array<U32> & U32) -> Array<U32> & U32:
  (a, acc) = s
  madd.x(q, acc, a[p])

def sum(+c: Nat, +p: U32, +q: U32, s: Array<U32> & U32) -> Array<U32> & U32:
  match c:
    case 0n:
      s
    case 1n+r:
      sum(r, (p + 1 : U32), (q + 1 : U32), madd(p, q, s))

# the same sum, which also adds one to each a[q] it reads
def maddw.y(+q: U32, +x: U32, acc: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (a, +y) = r
  (a[q] <- (y + 1 : U32), (acc * 3 + x + y : U32))

def maddw.x(+q: U32, acc: U32, r: Array<U32> & U32) -> Array<U32> & U32:
  (a, +x) = r
  maddw.y(q, x, acc, a[q])

def maddw(+p: U32, +q: U32, s: Array<U32> & U32) -> Array<U32> & U32:
  (a, acc) = s
  maddw.x(q, acc, a[p])

def sumw(+c: Nat, +p: U32, +q: U32, s: Array<U32> & U32) -> Array<U32> & U32:
  match c:
    case 0n:
      s
    case 1n+r:
      sumw(r, (p + 1 : U32), (q + 1 : U32), maddw(p, q, s))

type AB is Type:
  AB{a: Array<U32>, b: Array<U32>}

def put(+at: U32, b: Array<U32>, s: Array<U32> & U32) -> AB:
  (a, x) = s
  AB{a, b[at] <- x}

# b[o + j] = sum of row j of a, for c rows from j, a row w wide, rows step apart
def rows(+c: Nat, +j: U32, +o: U32, +w: U32, +step: U32, st: AB) -> AB:
  match c:
    case 0n:
      st
    case 1n+k:
      AB{a, b} = st
      rows(k, (j + step : U32), o, w, step,
        put((o + j : U32), b, sum(U32.to_nat(w), (j * w : U32), 5, (a, 1))))

# the same with a sum that writes what it reads: no lanes
def rows.w(+c: Nat, +j: U32, +w: U32, st: AB) -> AB:
  match c:
    case 0n:
      st
    case 1n+k:
      AB{a, b} = st
      rows.w(k, (j + 1 : U32), w,
        put(j, b, sumw(U32.to_nat(w), (j * w : U32), (j * w + 1 : U32), (a, 1))))

# the same, but each turn also writes the array it sums: no lanes
def put.self(+at: U32, b: Array<U32>, s: Array<U32> & U32) -> AB:
  (a, +x) = s
  AB{a[at] <- x, b[at] <- x}

def rows.self(+c: Nat, +j: U32, +w: U32, st: AB) -> AB:
  match c:
    case 0n:
      st
    case 1n+k:
      AB{a, b} = st
      rows.self(k, (j + 1 : U32), w,
        put.self((j * w + w : U32), b, sum(U32.to_nat(w), (j * w : U32), 5, (a, 1))))

# the turns swap the arrays: each turn sums the other one
def put.swap(+at: U32, b: Array<U32>, s: Array<U32> & U32) -> AB:
  (a, x) = s
  AB{b[at] <- x, a}

def rows.swap(+c: Nat, +j: U32, +w: U32, st: AB) -> AB:
  match c:
    case 0n:
      st
    case 1n+k:
      AB{a, b} = st
      rows.swap(k, (j + 1 : U32), w,
        put.swap(j, b, sum(U32.to_nat(w), (j * w : U32), 5, (a, 1))))

type ABC is Type:
  ABC{a: Array<U32>, b: Array<U32>, c: Array<U32>}

def put.alt(+at: U32, b: Array<U32>, c: Array<U32>, s: Array<U32> & U32) -> ABC:
  (a, x) = s
  ABC{b, a, c[at] <- x}

# the turns sum a and b in turn, and write c
def rows.alt(+n: Nat, +j: U32, +w: U32, st: ABC) -> ABC:
  match n:
    case 0n:
      st
    case 1n+k:
      ABC{a, b, c} = st
      rows.alt(k, (j + 1 : U32), w,
        put.alt(j, b, c, sum(U32.to_nat(w), (j * w : U32), 5, (a, 1))))

def out3(+m: U32, st: ABC) -> U32:
  ABC{a, b, c} = st
  ((hash(m, a) * 7 + hash(m, b)) * 7 + hash(m, c) : U32)

def out(+m: U32, st: AB) -> U32:
  AB{a, b} = st
  (hash(m, a) * 7 + hash(m, b) : U32)

def main() -> IO(Unit):
  do IO<Unit>:
    # 40 rows of 24 (past 16, and a count that is no multiple of 16)
    IO.print(U32.show(out(1024, rows(nat(40), v(0), v(0), v(24), v(1),
      AB{fill(nat(1024), v(0), Array.new(U32, 10n, 0)), Array.new(U32, 10n, 0)}))))
    # rows two apart, written one apart
    IO.print(U32.show(out(1024, rows(nat(33), v(0), v(100), v(9), v(2),
      AB{fill(nat(1024), v(0), Array.new(U32, 10n, 0)), Array.new(U32, 10n, 0)}))))
    # rows past the end of a: the reads wrap
    IO.print(U32.show(out(256, rows(nat(40), v(0), v(0), v(24), v(1),
      AB{fill(nat(256), v(0), Array.new(U32, 8n, 0)), Array.new(U32, 10n, 0)}))))
    # fewer than 16 rows, and short rows
    IO.print(U32.show(out(1024, rows(nat(9), v(0), v(0), v(24), v(1),
      AB{fill(nat(1024), v(0), Array.new(U32, 10n, 0)), Array.new(U32, 10n, 0)}))))
    IO.print(U32.show(out(1024, rows(nat(40), v(0), v(0), v(3), v(1),
      AB{fill(nat(1024), v(0), Array.new(U32, 10n, 0)), Array.new(U32, 10n, 0)}))))
    # each sum writes the cells it reads
    IO.print(U32.show(out(1024, rows.w(nat(40), v(0), v(24),
      AB{fill(nat(1024), v(0), Array.new(U32, 10n, 0)), Array.new(U32, 10n, 0)}))))
    # each turn writes the next row of the array it sums
    IO.print(U32.show(out(1024, rows.self(nat(40), v(0), v(24),
      AB{fill(nat(1024), v(0), Array.new(U32, 10n, 0)), Array.new(U32, 10n, 0)}))))
    # the turns sum two arrays in turn
    IO.print(U32.show(out3(1024, rows.alt(nat(40), v(0), v(24),
      ABC{fill(nat(1024), v(0), Array.new(U32, 10n, 0)), fill(nat(1024), v(5), Array.new(U32, 10n, 0)), Array.new(U32, 10n, 0)}))))
    # each turn sums the array the turn before wrote
    IO.print(U32.show(out(1024, rows.swap(nat(40), v(0), v(24),
      AB{fill(nat(1024), v(0), Array.new(U32, 10n, 0)), fill(nat(1024), v(1), Array.new(U32, 10n, 0))}))))

#|3376348800
#|3208771404
#|2396849408
#|615245607
#|2088999508
#|3963891243
#|621207528
#|3410503808
#|3272880056
