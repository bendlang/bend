# io (io_intrinsic_user_name): a user def named after a runtime
# function compiles its OWN checked body, in every backend. Each
# emitter wired ANY def whose lowercased name matched its runtime map
# (Cmp.new -> cmp_new, string_head -> string_head in tojs; U32.Div ->
# u32_div in tocl) straight to the native, the checked body silently
# dropped -- this program printed gt/13/H interpreted and lt/3/x
# compiled, the output-divergence class SPEC 1.8 names a launch
# blocker. Intrinsic wiring now requires a def with no implementation
# of its own -- base's (the b flag only base.bend mints) or a bodiless
# assert, never foreign: a filled user def never wires, whatever its
# name. Three spellings pin it: a dotted name in both maps (U32.Div),
# a runtime.js-only name (Cmp.new), and a bare underscore name
# (string_head).
import Base

law Cmp.new:
  for a: U32
  for b: U32
  Cmp

def Cmp.new(a, b):
  GT{}

law U32.Div:
  for a: U32
  for b: U32
  U32

def U32.Div(a, b):
  U32.add(a, b)

law show_cmp:
  for c: Cmp
  String

def show_cmp(c):
  match c:
    case LT{}:
      "lt"
    case EQ{}:
      "eq"
    case GT{}:
      "gt"

law string_head:
  for s: String
  String

def string_head(s):
  "H"

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    u : Unit <- IO.print(show_cmp(Cmp.new(1, 2)))
    v : Unit <- IO.print(U32.show(U32.Div(10, 3)))
    IO.print(string_head("xyz"))

#|gt
#|13
#|H
