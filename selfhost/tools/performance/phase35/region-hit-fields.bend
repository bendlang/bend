import Base

type HitProbe is Data:
  HitProbe{miss: Bool, distance: F32, index: U32}

# Terminal comparison fields keep their original constructor position. The
# public stages are Nat, two scalar values, then the final Bool match.
def hit.scan(count: Nat, +distance: F32, +index: U32, flag: Bool) -> HitProbe:
  match count flag:
    case 0n False{}:
      HitProbe{U32.is_eq(index, 9), distance, index}
    case 0n True{}:
      HitProbe{F32.is_le(distance, 0.0), distance, index}
    case 1n+k False{}:
      hit.scan(k, F32.add(distance, F32.div(U32.to_f32(1), U32.to_f32(2))), U32.add(index, 1), True{})
    case 1n+k True{}:
      hit.scan(k, F32.sub(distance, F32.div(U32.to_f32(1), U32.to_f32(4))), index, False{})

def main() -> HitProbe:
  hit.scan(9n, U32.to_f32(2), 7, False{})
