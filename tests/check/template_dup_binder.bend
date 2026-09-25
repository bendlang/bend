# two ~ binders of one name once collided in the generic check: each
# became the opaque constant cast~T, so the second overwrote the first
# and a body typed at the first checked at the second, which admitted
# a closed Empty (#905); the second name is now refused where it binds
type Unit is Data:
  Unit{}

def cast(~T: Type, ~x: T, ~T: Type) -> T:
  x

def main() -> Unit:
  Unit{}

#|Error:
#|- expected : a fresh ~ binder name
#|- observed : T
#|Location:
#|7 | 
#|8>| def cast(~T: Type, ~x: T, ~T: Type) -> T:
#|  |                            ^
#|9 |   x
#|exit 1
