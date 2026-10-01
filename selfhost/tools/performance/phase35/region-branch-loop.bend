import Base

# The public stages are Nat, then the U32 prefix, then Bool. Two residual
# Boolean arms carry different accumulator and next-flag values.
def branch(count: Nat, +sum: U32, flag: Bool) -> U32:
  match count flag:
    case 0n False{}: sum
    case 0n True{}: U32.add(sum, 7)
    case 1n+k False{}:
      branch(k, U32.add(sum, 3), True{})
    case 1n+k True{}:
      branch(k, U32.add(sum, 5), False{})

def float.branch(count: Nat, +sum: F32, flag: Bool) -> F32:
  match count flag:
    case 0n False{}: sum
    case 0n True{}: F32.sub(sum, U32.to_f32(1))
    case 1n+k False{}:
      +next = F32.add(sum, F32.div(U32.to_f32(1), U32.to_f32(10)))
      float.branch(k, next, F32.is_lt(next, U32.to_f32(10)))
    case 1n+k True{}:
      +next = F32.mul(sum, F32.div(U32.to_f32(11), U32.to_f32(10)))
      float.branch(k, next, F32.is_lt(next, U32.to_f32(10)))

def main() -> U32:
  branch(4096n, 17, False{})

# Alias spelling must not suppress the host guard before canonical F32 checks.
def FloatAlias() -> Type:
  F32

def alias.branch(count: Nat, ignored: FloatAlias, sum: U32, flag: Bool) -> U32:
  match count flag:
    case 0n False{}: sum
    case 0n True{}: U32.add(sum, 1)
    case 1n+k False{}:
      alias.branch(k, ignored, U32.add(sum, 2), True{})
    case 1n+k True{}:
      alias.branch(k, ignored, U32.add(sum, 3), False{})

def alias.loop(count: Nat, ignored: FloatAlias, sum: U32) -> U32:
  match count:
    case 0n: sum
    case 1n+k:
      alias.loop(k, ignored, U32.add(sum, 2))
