# Two overlapping subprocesses must not share pipes or strand each other's
# stdin EOF; their captured output belongs to the matching IO.fork action.
import Base

def start(input: String) -> IO(Result<&1, &1, U32 & String,
  U32 & (String & String)>):
  Process.run("/bin/cat", [], input, 128, 1000)

def answer(r: Result<&1, &1, U32 & String, U32 & (String & String)>,
  want: String) -> Bool:
  match r:
    case Fail{error}:
      False{}
    case Done{(code, (out, err))}:
      Bool.and(U32.is_eq(code, 0),
        Bool.and(String.eq(out, want), String.eq(err, "")))

def main() -> IO(Unit):
  do IO<Unit>:
    a : Chan(Result<&1, &1, U32 & String, U32 & (String & String)>) <-
      IO.fork(Result<&1, &1, U32 & String, U32 & (String & String)>,
        start("alpha"))
    b : Chan(Result<&1, &1, U32 & String, U32 & (String & String)>) <-
      IO.fork(Result<&1, &1, U32 & String, U32 & (String & String)>,
        start("beta"))
    x : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      IO.join(Result<&1, &1, U32 & String, U32 & (String & String)>, a)
    y : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      IO.join(Result<&1, &1, U32 & String, U32 & (String & String)>, b)
    IO.print(Bool.show(Bool.and(answer(x, "alpha"), answer(y, "beta"))))

#|True
