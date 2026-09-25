# a literal is a Nat by name only where Nat is Base's: a module's own Nat
# that declares Succ with another field checks the literal's unfolding, so
# 1n is refused as Succ{0n} where 0n is not an Empty (#941)
type Empty is Data:

type Nat is Data:
  Succ{e: Empty}

def extract(n: Nat) -> Empty:
  match n:
    case Succ{e}:
      e

def boom() -> Empty:
  extract(1n)

#|Error:
#|- expected : a declared constructor (Empty declares )
#|- observed : 0n
#|Location: boom
#|14 | def boom() -> Empty:
#|15>|   extract(1n)
#|   |           ^^
#|16 | 
#|exit 1
