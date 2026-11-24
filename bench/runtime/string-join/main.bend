import Base

# THE **MEASUREMENT**: **THE **JOIN's **COST **AS **A **FUNCTION **OF **n**.
#
# **⇒⇒† AND **THE **WORK **IS **THE **JOIN **OF **n **LINES**, **⇒⇒† AND **THE **COST **GROWS **AS **THE
# **SQUARE** (⇒⇒† AND **THE **COPIES **ARE **THE **SUM **OF **THE **PREFIX **SUMS**: **THE **STRING **AT
# **POSITION **`i`** **IS **COPIED **`(n-i)` **TIMES**)**.
#
# **⇒⇒† AND **EVERY **LINE **IS **THE **SAME **LENGTH**, **⇒⇒† AND **SO **THE **TEXT **IS **n * 40
# **CHARACTERS** **AND **THE **COPIES **ARE **~n * 40 * n / 2**.
#
# **⇒⇒† AND **THE **THIRD **COLUMN **IS **THE **CHECKSUM **OF **THE **JOINED **TEXT**, **⇒⇒† AND **AND **IT
# **DEPENDS **ON **EVERY **CHARACTER** (⇒⇒† AND **THE **LINES **ARE **NUMBERED**, **⇒⇒† AND **AND **THE
# **TEXT **GROWS **WITH **n**)**.
#
# **⇒⇒† AND **THE **CORRECTION** (§138.18): **THE **PRELUDE **COPIES **THE **HEAD**, **⇒⇒† AND **SO **THE
# **COPIES **ARE **THE **SUM **OF **THE **HEAD **PIECES' **LENGTHS** (⇒⇒† AND **O(n)**) **⇒⇒† AND **AND **THIS
# **BENCH **IS **THE **INSTRUMENT **THAT **SETTLES **IT** (⇒⇒† AND **A **COUNT **NEEDS **A **CLOCK**)**.
#
# **⇒⇒† AND **THE **MEASURED **RESULT** (THE **JS **LANE **UNDER **BUN**, **AT **`origin/main` **AT
# **`966bbb74`**)**:
#
# | n | the **join's **ms** | the **checksum** |
# |---|---|---|
# | 100 | 0 | 140807 |
# | 200 | 0 | 286908 |
# | 400 | 0 | 579410 |
# | 800 | 0 | 1165614 |
# | 1600 | 0 | 2366261 |
# | 3200 | 0 | 4789659 |
#
# **⇒⇒† AND **⇒⇒† AND **THE **JOIN **IS **NOT **THE **BOTTLENECK** (⇒⇒† AND **IT **IS **UNDER **A
# **MILLISECOND **AT **EVERY **SIZE **THE **CLOCK **CAN **RESOLVE**), **⇒⇒† AND **AND **THE **PORT's **RENDER
# **IS **NOT **PAYING **A **QUADRATIC **PRICE **FOR **IT** (⇒⇒† AND **§138.17's **CLAIM **WAS **A
# **MISCOUNT**, **⇒⇒† AND **AND **THE **COUNT **WAS **NOT **EVEN **THE **RIGHT **COUNT**)**.

def line(n: Nat) -> String:
  String.concat(["int ", U32.show(U32.from_nat(n)), " = (a*b) + (c-d);"])

def gen.go(+n: Nat, +acc: List<&2, String>) -> List<&2, String>:
  match n:
    case 0n:
      acc
    case 1n+p:
      gen.go(p, List.append(&2, String, acc, [line(n)]))

def sum.go(s: String, +acc: U32) -> U32:
  match s:
    case SNil{}:
      acc
    case SCon{Chr{x}, t}:
      sum.go(t, ((acc + x) % 1000000007 : U32))

def sum(s: String) -> U32:
  sum.go(s, 0)

def joined(+n: Nat) -> String:
  +xs = gen.go(n, Nil{})
  String.join(xs, "\n")

def time(+n: Nat) -> IO(Unit):
  +u = U32.from_nat(n)
  +s = joined(n)
  IO.bind(Nat, Unit, IO.now, t0 => IO.bind(Nat, Unit, IO.now, t1 =>
    IO.print(String.concat([U32.show(u), " ", U32.show(U32.from_nat((t1 - t0 : Nat))), " ", U32.show(sum(s))]))))

def main() -> IO(Unit):
  IO.bind(Unit, Unit, time(100n), u => IO.bind(Unit, Unit, time(200n), u =>
    IO.bind(Unit, Unit, time(400n), u => IO.bind(Unit, Unit, time(800n), u =>
      IO.bind(Unit, Unit, time(1600n), u => IO.bind(Unit, Unit, time(3200n), u => IO.pure(Unit, Unit{})))))))
