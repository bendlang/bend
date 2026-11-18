# Nat overflow where the 64-bit product wraps to a small number: 3 * 2^30
# times (2^34 + 2) / 3 is 2^64 + 2^31, which a machine word holds as 2^31,
# so only the test before the multiply sees it. The second operand is past
# 2^32 and the first is not, so this is Nat.mul's division path, taken for
# an operand on either side and from 2^32 on; nat_overflow's 2^24 * 2^24 is
# the path without a division. The operands are scaled by the command
# line's length (1 in the harness), which no compiler sees.
import Base

def wide(+one: Nat) -> Nat:
  Nat.mul(Nat.mul(3221225472n, one), Nat.add(4294967295n, Nat.mul(1431655767n, one)))

def main() -> IO(Unit):
  do IO<Unit>:
    xs : List<String> <- IO.args()
    IO.print(Nat.show(wide(List.length(&1, String, xs))))

#|bend: a Nat past the largest immediate 2^48-1
#|exit 1
