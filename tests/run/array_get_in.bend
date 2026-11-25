# A proved last-cell read returns the array for subsequent ordinary reads.
import Base

def then(r: Array<F32> & F32, k: Array<F32> -> F32 -> IO(Unit)) -> IO(Unit):
  match r:
    case Tuple{a, +x}:
      k(a, x)

def main() -> IO(Unit):
  then(Array.get_in(F32, [1.5 : F32*2n], 1, {==}), a => x =>
    then(Array.get(F32, a, 1), b => y =>
      then(Array.get(F32, b, 0), c => z =>
        IO.print(F32.show(F32.add(x, F32.add(y, z)))))))

#|4.5
