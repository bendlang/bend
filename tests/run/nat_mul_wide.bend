# Nat.mul's overflow test divides only when an operand reaches 2^32: under
# that the 64-bit product is exact, and nat_chk alone holds it to 2^48-1.
# Every operand is scaled by the command line's length (1 in the harness),
# which no compiler sees, so no lane folds a row. The rows sit on both
# sides of 2^32 in either operand, and at the largest Nat as a product:
# (2^24-1) * (2^24+1) = 2^48-1 with both operands small, (2^32+2^16+1) *
# 65535 = 2^48-1 with one operand wide, 2^32 * 65535 and 2^40 * 255.
# nat_overflow and nat_overflow_wide are the products past the wall.
import Base

def big() -> Nat:
  Nat.add(Nat.mul(16777215n, 16777216n), 16777215n)

def row(a: Nat, b: Nat) -> String:
  Nat.show(Nat.mul(a, b))

def rows(+one: Nat) -> String:
  String.join([
    row(Nat.mul(0n, one), big()),
    row(big(), Nat.mul(0n, one)),
    row(one, big()),
    row(big(), one),
    row(Nat.mul(16777215n, one), Nat.mul(16777217n, one)),
    row(Nat.mul(16777217n, one), Nat.mul(16777215n, one)),
    row(Nat.mul(4294967295n, one), Nat.mul(65535n, one)),
    row(Nat.mul(65535n, one), Nat.mul(4294967295n, one)),
    row(Nat.add(4294967295n, one), Nat.mul(65535n, one)),
    row(Nat.mul(65535n, one), Nat.add(4294967295n, one)),
    row(Nat.add(4294967295n, Nat.mul(2n, one)), Nat.mul(65535n, one)),
    row(Nat.mul(1048576n, Nat.mul(1048576n, one)), Nat.mul(255n, one)),
    row(Nat.mul(255n, one), Nat.mul(1048576n, Nat.mul(1048576n, one))),
    row(Nat.mul(16777216n, one), Nat.mul(8388608n, one)),
    row(Nat.add(4294967295n, Nat.mul(65538n, one)), Nat.mul(65535n, one)),
    row(Nat.mul(65535n, one), Nat.add(4294967295n, Nat.mul(65538n, one))),
    row(Nat.mul(4294967295n, one), Nat.mul(0n, one)),
    row(Nat.add(4294967295n, one), Nat.mul(0n, one))], "\n")

def main() -> IO(Unit):
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(rows(List.length(&1, String, xs)))

#|0
#|0
#|281474976710655
#|281474976710655
#|281474976710655
#|281474976710655
#|281470681677825
#|281470681677825
#|281470681743360
#|281470681743360
#|281470681808895
#|280375465082880
#|280375465082880
#|140737488355328
#|281474976710655
#|281474976710655
#|0
#|0
