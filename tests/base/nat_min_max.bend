# Nat.min and Nat.max are one machine comparison on the JS and C lanes:
# on two Nats near 2^40 Base's structural definitions, run as written,
# recurse 2^40 deep and overflow the stack; compared, each line prints at
# once. The edges: 0 with 0, 0 with n on either side, equal values, a < b,
# a > b; then Nat.max inside the lambda List.foldl takes as its template
# argument, and Nat.min in a closure.
import Base

def big(k: Nat) -> Nat:
  Nat.add(Nat.mul(1048576n, 1048576n), k)

def ap(f: Nat -> Nat -> Nat, a: Nat, b: Nat) -> Nat:
  f(a, b)

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(Nat.show(Nat.min(0n, 0n)))
    IO.print(Nat.show(Nat.max(0n, 0n)))
    IO.print(Nat.show(Nat.min(0n, 7n)))
    IO.print(Nat.show(Nat.max(0n, 7n)))
    IO.print(Nat.show(Nat.min(7n, 0n)))
    IO.print(Nat.show(Nat.max(7n, 0n)))
    IO.print(Nat.show(Nat.min(7n, 7n)))
    IO.print(Nat.show(Nat.max(7n, 7n)))
    IO.print(Nat.show(Nat.min(3n, 9n)))
    IO.print(Nat.show(Nat.max(3n, 9n)))
    IO.print(Nat.show(Nat.min(9n, 3n)))
    IO.print(Nat.show(Nat.max(9n, 3n)))
    IO.print(Nat.show(Nat.min(big(3n), big(5n))))
    IO.print(Nat.show(Nat.max(big(3n), big(5n))))
    IO.print(Nat.show(Nat.min(big(5n), big(3n))))
    IO.print(Nat.show(Nat.max(big(5n), big(3n))))
    IO.print(Nat.show(Nat.min(big(4n), big(4n))))
    IO.print(Nat.show(Nat.max(big(4n), big(4n))))
    IO.print(Nat.show(Nat.min(0n, big(0n))))
    IO.print(Nat.show(Nat.max(big(0n), 0n)))
    IO.print(Nat.show(List.foldl(~&2, ~Nat, ~Nat, ~(a => b => Nat.max(a, b)),
      [big(2n), 7n, big(9n), 0n], 0n)))
    IO.print(Nat.show(ap(a => b => Nat.min(a, b), big(8n), big(6n))))

#|0
#|0
#|0
#|7
#|0
#|7
#|7
#|7
#|3
#|9
#|3
#|9
#|1099511627779
#|1099511627781
#|1099511627779
#|1099511627781
#|1099511627780
#|1099511627780
#|0
#|1099511627776
#|1099511627785
#|1099511627782
