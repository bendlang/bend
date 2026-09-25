# comp pin (parse_comp_arrow_position): bend3's comp arrow -~> in a
# term-level type position (a let's type) named its own page. bend has
# no -~> arrow anywhere (and no typed let: the Ann brace {v : T} is the
# spelling); the arrow pins bend's own parse refusal.
import Base

law f:
  for x: U32
  U32

def f(x):
  h = {y => y : U32 -~> U32}
  h(x)

law main:
  U32

def main():
  f(3)

#|Error:
#|- expected : a term
#|- observed : '~'
#|Location:
#|11 | def f(x):
#|12>|   h = {y => y : U32 -~> U32}
#|   |                      ^
#|13 |   h(x)
#|exit 1
