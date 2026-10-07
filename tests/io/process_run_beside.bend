# Process.run parks only its own computation: the others run while the
# child does (the C lane's helper thread, the JS lane's poller), so main
# prints before the slow child answers.
import Base

def report(r: Result<&1, &1, U32 & String, U32 & (String & String)>) ->
  IO(Unit):
  match r:
    case Done{(code, (out, err))}:
      IO.print("child: " ++ out)
    case Fail{error}:
      IO.print("child: unexpected failure")

def slow() -> IO(Unit):
  do IO<Unit>:
    r : Result<&1, &1, U32 & String, U32 & (String & String)> <-
      Process.run("/bin/sh", ["-c", "sleep 0.5; printf slow"], "", 128, 5000)
    report(r)

def main() -> IO(Unit):
  do IO<Unit>:
    c : Chan(Unit) <- IO.fork(Unit, slow())
    x : Unit <- IO.sleep(50)
    y : Unit <- IO.print("beside")
    IO.join(Unit, c)

#|beside
#|child: slow
