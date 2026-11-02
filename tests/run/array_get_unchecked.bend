# Array.get_unchecked is a read the caller promises is below the block's
# capacity: it skips the wrap mask. It returns the array like Array.get.
import Base

def then(r: Array<F32> & F32, k: Array<F32> -> F32 -> IO(Unit)) -> IO(Unit):
  match r:
    case Tuple{a, +x}:
      k(a, x)

@unsafe
def main() -> IO(Unit):
  do IO<Unit>:
    then(Array.get_unchecked(F32, [1.5 : F32*2n], 1), a => x =>
      then(Array.get(F32, a, 1), b => y =>
        then(Array.get(F32, b, 0), c => z =>
          IO.print(F32.show(F32.add(x, F32.add(y, z)))))))

#|4.5
