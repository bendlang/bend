# two calls of one def on a different number of arguments are not
# rigidly equal, even when the arguments they share are: g(1n)(0n) is 7n
# and g(0n) is 5n
import Base

def Fun(n: Nat) -> Type:
  match n:
    case 0n: Nat
    case 1n+p: Nat -> Nat

def g(n: Nat) -> Fun(n):
  match n:
    case 0n: 5n
    case 1n+p: {x => 7n : Nat -> Nat}

def bad() -> {g(1n)(0n) == g(0n) : Nat}:
  {==}

#|SOME PROOFS FAIL
#|Error:
#|- expected : 7n
#|- observed : 5n
#|Location: bad
#|16 | def bad() -> {g(1n)(0n) == g(0n) : Nat}:
#|17>|   {==}
#|   |   ^^^^
#|18 | 
#|exit 1
