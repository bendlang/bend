# A JS effect's answer crosses the typed String/Char callback boundary.
# Valid scalar endpoints stay one character. A lone surrogate is rejected
# before concatenation or reversal can silently change its meaning.
import Base

law low:
  IO(String)

def low():
  import "./string_host_scalar.js"

law high:
  IO(String)

def high():
  import "./string_host_scalar.js"

law apex:
  IO(String)

def apex():
  import "./string_host_scalar.js"

law edge:
  IO(Char)

def edge():
  import "./string_host_scalar.js"

law torn:
  IO(String)

def torn():
  import "./string_host_scalar.js"

law count:
  for s: String
  U32

def count(s):
  match s:
    case SNil{}:
      0
    case SCon{h, t}:
      U32.add(1, count(t))

law code_of:
  for c: Char
  U32

def code_of(c):
  match c:
    case Chr{n}:
      n

law main:
  IO(U32)

def main():
  do IO<U32>:
    a : String <- low()
    b : String <- high()
    c : String <- apex()
    d : Char <- edge()
    u : Unit <- IO.print(U32.show(count(a)))
    v : Unit <- IO.print(U32.show(count(b)))
    w : Unit <- IO.print(U32.show(count(c)))
    x : Unit <- IO.print(U32.show(code_of(d)))
    e : String <- torn()
    y : Unit <- IO.print(U32.show(count(e)))
    return 0

#|1
#|1
#|1
#|55295
#|bend: 55296 is not a Unicode scalar value
#|exit 1
