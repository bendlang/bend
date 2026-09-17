# io (io_audio_open): Audio.open answers Done{Audio} on a machine with an
# output, Fail on one without (a node with no audio device; the JS lane's
# silent stub answers Done); either way the write and close paths return
# cleanly: 512 frames of silence written to an open device queue at most
# 512, a failed open is reported once, and the last line is the same on
# every lane.
import Base

law zeros:
  for n: Nat
  List<&2, F32>

def zeros(n):
  match n:
    case 0n:
      Nil{}
    case 1n+k:
      0.0 <> 0.0 <> zeros(k)

law Math.word:
  for c: Bool
  for a: String
  for b: String
  String

def Math.word(c, a, b):
  match c:
    case True{}:
      a
    case False{}:
      b

law wrote:
  for r: Audio & U32
  IO(Unit)

def wrote(r):
  (a, +q) = r
  do IO<Unit>:
    u : Unit <- IO.print(Math.word((q <= 512 : U32), "queued", "over"))
    Audio.close(a)

law opened:
  for r: Result<&1, &1, (U32 & String), Audio>
  IO(Unit)

def opened(r):
  match r:
    case Fail{(code, text)}:
      IO.print("queued")
    case Done{a}:
      do IO<Unit>:
        w : Audio & U32 <- Audio.write(a, zeros(U32.to_nat(512)))
        wrote(w)

law main:
  IO(Unit)

def main():
  do IO<Unit>:
    r : Result<&1, &1, (U32 & String), Audio> <- Audio.open(48000)
    u : Unit <- opened(r)
    IO.print("closed")

#|queued
#|closed
