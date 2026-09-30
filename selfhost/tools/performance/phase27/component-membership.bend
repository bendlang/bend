# Phase27 actual compiler has_name/has_name_next component
import Base

@unsafe
def has_name(
  +ns: List<&2, String>,
  +name: String,
) -> Bool:
  match ns:
    case Nil{}:
      False{}
    case Con{h, t}:
      has_name_next(t, name, String.eq(h, name))

@unsafe
def has_name_next(+rest: List<&2,String>, +name: String, +same: Bool) -> Bool:
  match same:
    case True{}: True{}
    case False{}: has_name(rest, name)


# Wrapper: build one list, then run the unmodified compiler membership helper.
# This sole-argument builder has no remaining argument after its Nat match,
# so selected-arm prebinding should not change its own partial-application path.
@unsafe
def component_names(n: Nat) -> List<&2,String>:
  match n:
    case 0n: Con{"target", Nil{}}
    case 1n+p: Con{"same", component_names(p)}

def component_query(b: Bool) -> String:
  match b:
    case True{}: "target"
    case False{}: "absent"

def component_result(b: Bool) -> U32:
  match b:
    case True{}: 1
    case False{}: 0

@unsafe
def bench(+size: U32, +seed: U32) -> U32:
  U32.add(seed, component_result(has_name(component_names(U32.to_nat(size)), component_query(U32.is_even(seed)))))
