import Base

# Cancelling the same offset leaves the remainder, with a non-Boolean result.
def remaining(left: Nat, right: Nat) -> Nat:
  match left:
    case 0n:
      right
    case 1n+x:
      match right:
        case 0n:
          1n+x
        case 1n+y:
          remaining(x, y)

# Similar syntax, but doing work after recursion must preserve every step.
def counted(left: Nat, right: Nat) -> Nat:
  match left:
    case 0n:
      right
    case 1n+x:
      match right:
        case 0n:
          1n+x
        case 1n+y:
          1n+counted(x, y)

def less() -> {remaining(17n, 21n) == 4n : Nat}:
  {==}

def more() -> {remaining(21n, 17n) == 4n : Nat}:
  {==}

def same() -> {remaining(17n, 17n) == 0n : Nat}:
  {==}

def symbolic(x: Nat, y: Nat) -> {remaining(1n+x, 1n+y) == remaining(x, y) : Nat}:
  {==}

def preserve_work() -> {counted(17n, 21n) == 21n : Nat}:
  {==}

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
