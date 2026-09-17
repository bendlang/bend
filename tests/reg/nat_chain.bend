# a match on a Nat whose literal patterns lead to arms that are not
# constants goes out as one flat if/else-if chain over the word, each
# level comparing the scrutinee to its literal and binding a default's
# variable to the word minus the level. The Succ peels the literals
# desugar to used to nest one block per unit, so a match against 'z'
# (122n) sat 250 columns deep. The emit-style lane pins the width.
import Base

type Opts is Data:
  Opts{mode: U32, gz: Bool, verbose: Bool}

def bit(b: Bool, n: U32) -> U32:
  match b:
    case True{}:
      n
    case False{}:
      0

def flag(c: Nat, o: Opts) -> Opts:
  match c, o:
    case 99n, Opts{mode, gz, verbose}:
      Opts{1, gz, verbose}
    case 120n, Opts{mode, gz, verbose}:
      Opts{2, gz, verbose}
    case 122n, Opts{mode, gz, verbose}:
      Opts{mode, True{}, verbose}
    case 118n, Opts{mode, gz, verbose}:
      Opts{mode, gz, True{}}
    case k, Opts{mode, gz, verbose}:
      Opts{4, gz, verbose}

def show(o: Opts) -> U32:
  match o:
    case Opts{mode, gz, verbose}:
      (mode * 100 + bit(gz, 10) + bit(verbose, 1) : U32)

def main() -> IO(Unit):
  +b = flag(U32.to_nat(122), flag(U32.to_nat(120), Opts{0, False{}, False{}}))
  d = flag(U32.to_nat(118), flag(U32.to_nat(7), b))
  IO.print(U32.show((show(d) * 1000 + show(b) : U32)))

#|411210
