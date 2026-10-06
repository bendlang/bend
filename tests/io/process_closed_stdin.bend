# Pipe descriptors must not alias the child's standard descriptors when
# the parent has closed stdin. Both lanes still feed and capture /bin/cat.
import Base

law shut_stdin:
  IO(Unit)

def shut_stdin():
  import "./process_closed_stdin.js"
  import "./process_closed_stdin.c"

def report(r: Result<&1, &1, U32 & String, U32 & (String & String)>) -> IO(Unit):
  match r:
    case Done{(code, (out, err))}:
      IO.print(U32.show(code) ++ ":" ++ out ++ ":" ++ err)
    case Fail{(code, message)}:
      IO.print("fail:" ++ U32.show(code))

def main() -> IO(Unit):
  do IO<Unit>:
    Unit <- shut_stdin()
    r : Result<&1, &1, U32 & String, U32 & (String & String)> <- Process.run("/bin/cat", [], "payload", 128, 1000)
    report(r)

#|0:payload:
