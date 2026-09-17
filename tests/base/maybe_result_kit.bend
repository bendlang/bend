# the Maybe, Result and Pair kit: default, is_some/is_none, map, or,
# show; Result default, is_done/is_fail, map; Pair.fst and Pair.snd
import Base

def mu(m: Maybe<&2, U32>) -> String:
  Maybe.show(~&2, ~U32, ~(x => U32.show(x)), m)

def ru(r: Result<&2, &2, String, U32>) -> String:
  match r:
    case Fail{e}:
      "Fail(" ++ e ++ ")"
    case Done{x}:
      "Done(" ++ U32.show(x) ++ ")"

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(U32.show(Maybe.default(&2, U32, Some{5}, 9)))
    IO.print(U32.show(Maybe.default(&2, U32, None{}, 9)))
    IO.print(Bool.show(Maybe.is_some(&2, U32, Some{1})))
    IO.print(Bool.show(Maybe.is_none(&2, U32, Some{1})))
    IO.print(mu(Maybe.map(&2, U32, U32, x => U32.add(x, 1), Some{1})))
    IO.print(mu(Maybe.map(&2, U32, U32, x => U32.add(x, 1), None{})))
    IO.print(mu(Maybe.or(&2, U32, None{}, Some{3})))
    IO.print(mu(Maybe.or(&2, U32, Some{2}, Some{3})))
    IO.print(U32.show(Result.default(&2, &2, String, U32, Done{4}, 0)))
    IO.print(U32.show(Result.default(&2, &2, String, U32, Fail{"e"}, 0)))
    IO.print(Bool.show(Result.is_done(&2, &2, String, U32, Done{4})))
    IO.print(Bool.show(Result.is_fail(&2, &2, String, U32, Done{4})))
    IO.print(ru(Result.map(&2, &2, String, U32, U32, x => U32.mul(x, 2), Done{4})))
    IO.print(ru(Result.map(&2, &2, String, U32, U32, x => U32.mul(x, 2), Fail{"bad"})))
    IO.print(U32.show(Pair.fst(U32, String, (7, "x"))))
    IO.print(Pair.snd(U32, String, (7, "x")))

#|5
#|9
#|True
#|False
#|Some(2)
#|None
#|Some(3)
#|Some(2)
#|4
#|0
#|True
#|False
#|Done(8)
#|Fail(bad)
#|7
#|x
