# gfx (gfx_app_linear): an App's state may be linear (App<S> binds
# S: Type): view threads a File back beside its Image, tick writes a
# line per frame through it, the program closes it and reads the log.
import Base

type Log is Type:
  Log{file: File, n: U32}

def Log.view(s: Log) -> Log & Image:
  Log{file, +n} = s
  (Log{file, n}, Pix{n})

def Log.next(w: File & Result<&1, &1, U32 & String, Unit>, n: U32) ->
  IO(Maybe<Log>):
  (file, r) = w
  do IO<Maybe<Log>>:
    u : Unit <- IO.pass(Unit, r)
    IO.pure(Maybe<Log>, Some{Log{file, U32.inc(n)}})

def Log.tick(events: List<Event>, s: Log) -> IO(Maybe<Log>):
  Log{file, +n} = s
  do IO<Maybe<Log>>:
    w : File & Result<&1, &1, U32 & String, Unit> <-
      File.write(file, "frame " ++ U32.show(n) ++ "\n")
    Log.next(w, n)

def read_go(m: File & Result<&1, &1, U32 & String, String>) -> IO(Unit):
  (f, r) = m
  do IO<Unit>:
    data : String <- IO.pass(String, r)
    u : Unit <- IO.write(data)
    File.close(f)

def closed(m: Maybe<Log>) -> IO(Unit):
  match m:
    case None{}:
      IO.print("quit")
    case Some{s}:
      Log{file, n} = s
      do IO<Unit>:
        u : Unit <- IO.print("frames " ++ U32.show(n))
        v : Unit <- File.close(file)
        g : File <- IO.try(File, File.open("/tmp/bend_gfx_linear.tmp", "r"))
        m : File & Result<&1, &1, U32 & String, String> <- File.read(g, 64)
        read_go(m)

def main() -> IO(Unit):
  do IO<Unit>:
    f : File <- IO.try(File, File.open("/tmp/bend_gfx_linear.tmp", "w"))
    m : Maybe<Log> <- App.play(~Log, ~App{Log.view, Log.tick}, [[], [Close{}], []],
      Log{f, 0})
    closed(m)

#|frames 3
#|frame 0
#|frame 1
#|frame 2
