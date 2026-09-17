# io (io_get_env_own): get_env reads the environment's OWN keys
# only, so "toString" is unset. The JS lookup once reached through
# process.env's prototype and answered Object.prototype.toString, a
# function no marshal can carry.
import Base

law report:
  for tag : String
  for r   : Result<&1, &1, (U32 & String), String>
  IO(Unit)

def report(tag, r):
  match r:
    case Done{value}:
      IO.print(String.append(tag, "=set"))
    case Fail{error}:
      (code, message) = error
      IO.print(String.append(tag, "=unset"))

law main:
  IO(U32)

def main():
  do IO<U32>:
    a : Result<&1, &1, (U32 & String), String> <- IO.get_env("toString")
    x : Unit <- report("toString", a)
    b : Result<&1, &1, (U32 & String), String> <- IO.get_env("hasOwnProperty")
    y : Unit <- report("hasOwnProperty", b)
    return 0

#|toString=unset
#|hasOwnProperty=unset
