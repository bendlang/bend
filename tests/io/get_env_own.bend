# io (io_get_env_own): get_env reads the environment's OWN keys
# only, so "toString" is unset. The JS lookup once reached through
# process.env's prototype and answered Object.prototype.toString, a
# function no marshal can carry.
# Node's environment proxy must not truncate a NUL-containing name to
# HOME; the existing get_env fixture also requires HOME to be set.
import Base

def report_error(tag: String, code: U32) -> IO(Unit):
  match code:
    case 2:
      IO.print(String.append(tag, "=unset"))
    case other:
      IO.print(String.append(tag, String.append("=error:", U32.show(other))))

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
      report_error(tag, code)

law main:
  IO(U32)

def main():
  do IO<U32>:
    a : Result<&1, &1, (U32 & String), String> <- IO.get_env("toString")
    x : Unit <- report("toString", a)
    b : Result<&1, &1, (U32 & String), String> <- IO.get_env("hasOwnProperty")
    y : Unit <- report("hasOwnProperty", b)
    c : Result<&1, &1, (U32 & String), String> <- IO.get_env("HOME\0suffix")
    z : Unit <- report("HOME_NUL", c)
    return 0

#|toString=unset
#|hasOwnProperty=unset
#|HOME_NUL=unset
