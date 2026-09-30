import Base

# These helpers must stay distinct. Foreign-name case folding would collide.
def step(+x: U32) -> U32:
  U32.add(x, 3)

def Step(+x: U32) -> U32:
  U32.mul(x, 5)

def step_1(+x: U32) -> U32:
  U32.xor(x, 2654435761)

def step1(+x: U32) -> U32:
  U32.add(x, 1013904223)

def loop(n: Nat, +x: U32) -> U32:
  match n:
    case 0n:
      Step(step(x))
    case 1n+p:
      loop(p, step1(step_1(Step(step(x)))))

def bench(n: U32, +seed: U32) -> U32:
  loop(U32.to_nat(n), seed)
