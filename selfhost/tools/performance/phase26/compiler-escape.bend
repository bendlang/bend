# Phase26 actual JavaScript emitter string-escaping component
import Base

@unsafe
def j_escape(
  +s: String,
) -> String:
  match s:
    case SNil{}:
      ""
    case SCon{c, t}:
      j_escape_char(c) ++ j_escape(t)

law j_escape_char:
  for +c: Char
  String

@unsafe
def j_escape_char(c):
  j_escape_char_on(c, Char.to_u32(c))

law j_escape_char_on:
  for +c: Char
  for +key: U32
  String

@unsafe
def j_escape_char_on(c, key):
  match key:
    case 34:
      "\\\""
    case 92:
      "\\\\"
    case 10:
      "\\n"
    case 13:
      "\\r"
    case 9:
      "\\t"
    case 0:
      "\\x00"
    case n:
      Char.show(Char.from_u32(n))


# Wrapper only: runtime input construction and complete output-codepoint checksum.
# The compiler helper definitions above are copied byte-for-byte from emit.bend.
@unsafe
def component_unit(+seed: U32) -> String:
  Char.show(Char.from_u32(U32.add(65, U32.mod(seed, 26)))) ++ "\"\\\n\r\t\0λ雪𝄞az09"

@unsafe
def component_repeat(+n: Nat, +unit: String) -> String:
  match n:
    case 0n: ""
    case 1n+p: unit ++ component_repeat(p, unit)

@unsafe
def component_text(+size: U32, +seed: U32) -> String:
  component_repeat(U32.to_nat(size), component_unit(seed))

@unsafe
def escape_text(+size: U32, +seed: U32) -> String:
  j_escape(component_text(size, seed))

@unsafe
def component_sum(s: String, acc: U32) -> U32:
  match s:
    case SNil{}: acc
    case SCon{c, rest}: component_sum(rest, U32.add(acc, Char.to_u32(c)))

@unsafe
def bench(+size: U32, +seed: U32) -> U32:
  component_sum(escape_text(size, seed), seed)
