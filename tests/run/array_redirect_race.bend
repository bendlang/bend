# shared-array reads must not race updates to the redirect's refcount (#975)
# run the emitted C with -fsanitize=thread and at least two workers
import Base

@unsafe
def leaf(a: Array<U32>) -> Array<U32>:
  Array.set.fin(U32, Array.atomic.add(a, 0, 1))

@unsafe
def fan(+d: Nat, +a: Array<U32>) -> Array<U32>:
  match d:
    case 0n:
      leaf(a)
    case 1n+p:
      l r = fan(p, a) fan(p, a)
      Array.join(U32, l, r)

def done(r: Array<U32> & U32) -> IO(Unit):
  (a, x) = r
  IO.print(U32.show(x))

def main() -> IO(Unit):
  done(Array.get(U32, fan!(8n, [0 : U32*1n]), 0))

#|256
