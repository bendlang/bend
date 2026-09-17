# the List templates: filter, foldl, foldr, any, all, find, contains,
# sort (a stable bottom-up merge sort under a length fuel) and
# for_each
import Base

def u32s(xs: List<&2, U32>) -> String:
  List.show(~&2, ~U32, ~(x => U32.show(x)), xs)

def strs(xs: List<&2, String>) -> String:
  List.show(~&2, ~String, ~(s => s), xs)

def mu(m: Maybe<&2, U32>) -> String:
  Maybe.show(~&2, ~U32, ~(x => U32.show(x)), m)

def cons(h: U32, t: List<&2, U32>) -> List<&2, U32>:
  h <> t

def is_odd(x: U32) -> Bool:
  Bool.not(U32.is_even(x))

def main() -> IO(Unit):
  do IO<Unit>:
    IO.print(u32s(List.filter(~U32, ~is_odd, [1, 2, 3, 4, 5])))
    IO.print(U32.show(List.foldl(~&2, ~U32, ~U32, ~U32.add, [1, 2, 3], 10)))
    IO.print(u32s(List.foldr(~&2, ~U32, ~List<&2, U32>, ~cons, [1, 2, 3], [9])))
    IO.print(Bool.show(List.any(~&2, ~U32, ~is_odd, [2, 4, 5])))
    IO.print(Bool.show(List.any(~&2, ~U32, ~is_odd, [2, 4])))
    IO.print(Bool.show(List.all(~&2, ~U32, ~is_odd, [1, 3])))
    IO.print(Bool.show(List.all(~&2, ~U32, ~is_odd, [1, 2])))
    IO.print(mu(List.find(~U32, ~is_odd, [2, 3, 5])))
    IO.print(mu(List.find(~U32, ~is_odd, [2, 4])))
    IO.print(Bool.show(List.contains(~U32, ~U32.is_eq, [1, 2, 3], 2)))
    IO.print(Bool.show(List.contains(~U32, ~U32.is_eq, [1, 2, 3], 9)))
    IO.print(u32s(List.sort(~U32, ~U32.is_le, [5, 3, 9, 1, 4, 1, 8])))
    IO.print(u32s(List.sort(~U32, ~U32.is_le, [])))
    IO.print(u32s(List.sort(~U32, ~U32.is_ge, [2, 1, 3])))
    IO.print(strs(List.sort(~String, ~String.is_le, ["pear", "apple", "fig"])))
    List.for_each(~&2, ~U32, ~(x => IO.print(U32.show(x))), [1, 2])

#|[1, 3, 5]
#|16
#|[1, 2, 3, 9]
#|True
#|False
#|True
#|False
#|Some(3)
#|None
#|True
#|False
#|[1, 1, 3, 4, 5, 8, 9]
#|[]
#|[3, 2, 1]
#|[apple, fig, pear]
#|1
#|2
