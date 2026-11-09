# --verdict must use one instance for renamed template binders.
import Base

def renamed(xs: List<Bool>) ->
  {List.map(~Bool, ~Bool, ~(x => x), xs) ==
   List.map(~Bool, ~Bool, ~(y => y), xs) : List<Bool>}:
  {==}

def nested(~f: Bool -> Bool -> Bool, xs: List<Bool>, +b: Bool) -> List<Bool>:
  match xs:
    case []: []
    case x <> tail: f(x, b) <> nested(~f, tail, b)

def renamed_nested(xs: List<Bool>, +b: Bool) ->
  {nested(~(x => y => x), xs, b) ==
   nested(~(a => b => a), xs, b) : List<Bool>}:
  {==}

def renamed_types(xs: List<(Bool -> Bool)>) ->
  {List.map(~(@x: Bool -> Bool), ~(@x: Bool -> Bool), ~(f => f), xs) ==
   List.map(~(@y: Bool -> Bool), ~(@y: Bool -> Bool), ~(g => g), xs) : List<(Bool -> Bool)>}:
  {==}

# Different variable levels and constructor names must stay distinct.
def outer() ->
  {nested(~(x => y => x), [True{}], False{}) == [True{}] : List<Bool>}:
  {==}

def inner() ->
  {nested(~(x => y => y), [True{}], False{}) == [False{}] : List<Bool>}:
  {==}

def true_value() ->
  {List.map(~Bool, ~Bool, ~(x => True{}), [False{}]) == [True{}] : List<Bool>}:
  {==}

def false_value() ->
  {List.map(~Bool, ~Bool, ~(x => False{}), [True{}]) == [False{}] : List<Bool>}:
  {==}

#|ALL PROOFS CHECK
#|Use --verdict for mathematical validity.
