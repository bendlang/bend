# a bang over a record holding a grown family and a closure, where the
# closure's type is named after the family plus "false": the walk keys the
# rejected Ch<1n> apart from Chfalse, so it still opens Chfalse and puts the
# closure on the device (#2112: both keyed "Chfalse", and the device stopped
# with "a function the device does not hold")
import Base

type Ch<-n: Nat> is Data:
  End{}
  Link{next: Ch<(1n + n : Nat)>}

type Chfalse is Type:
  Fn{f: U32 -> U32}

type Duo is Type:
  Duo{chain: Ch<0n>, callable: Chfalse}

def use(d: Duo) -> U32:
  match d:
    case Duo{chain, callable}:
      match callable:
        case Fn{f}:
          f(41)

def main() -> IO(Unit):
  IO.print(U32.show(use!(Duo{End{}, Fn{x => (x + 1 : U32)}})))

#|42
