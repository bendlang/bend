# regression witness: ty_holds keys a recursive instance by name + arguments,
# and for a rejected instance it has to say "too big to walk, so unknown".
# The key used to be t.k + (!re && xs), so a rejected Ch<n> (re true) keyed
# as "Chfalse" and collided with the unrelated type Chfalse. The walk then
# believed it had already seen that type, treated its Fn field as unknown,
# and left the closure out of the GPU program; calling it on the device
# stopped with "a function the device does not hold". A name that ends in
# "false" is enough to collide, so this needs no other spelling.
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

def main() -> U32:
  use!(Duo{End{}, Fn{x => (x + 1 : U32)}})

#|42
