# the slot count after * is read up to the nat cap: 2n+4294967295n is not
# a count, so it is refused as one (it summed past the cap to 4294967297,
# whose 32-bit power of two test passed and whose log2 made a fractional
# depth: a Nat that no Succ chain reaches, defeating termination) (#954)
type Nat is Data:
  Zero{}
  Succ{pred: Nat}

def Array.new(-T: Type, d: Nat, x: T) -> Nat:
  d

def bad() -> Nat:
  [0n : Nat*2n+4294967295n]

#|Error:
#|- message  : a power of two count (^d takes a depth)
#|Location:
#|12 | def bad() -> Nat:
#|13>|   [0n : Nat*2n+4294967295n]
#|   |             ^^^^^^^^^^^^^^
#|14 | 
#|exit 1
