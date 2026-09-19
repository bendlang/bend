# File.read_text: a file read in chunks through a Utf8.Dec appends to its
# whole-file File.read decode, wherever the chunk boundaries cut a scalar.
# The scan keeps only a hash, two counts and a flag between chunks, so the
# answer for every chunk size must be the whole-file line. The byte fixture
# carries the BOM, NUL, ill-formed and truncated sequences; the corpus puts
# 2-, 3- and 4-byte scalars at every offset of a 7-byte chunk (17-byte unit).
import Base

type Scan is Data:
  Scan{hash: U32, chars: U32, words: U32, gap: Bool}

def Scan.starts(gap: Bool, space: Bool) -> U32:
  match gap space:
    case True{} False{}:
      1
    case g s:
      0

def Scan.text(s: String, st: Scan) -> Scan:
  match s st:
    case SNil{} st:
      st
    case SCon{+c, t} Scan{h, n, w, gap}:
      +space = Char.is_space(c)
      Scan.text(t, Scan{String.hash.cell(h, Char.to_u32(c)), (n + 1 : U32),
        (w + Scan.starts(gap, space) : U32), space})

def Scan.show(st: Scan) -> String:
  Scan{h, n, w, gap} = st
  U32.show(h) ++ " " ++ U32.show(n) ++ " chars " ++ U32.show(w) ++ " words"

def choose(-A: Type, b: Bool, yes: Unit -> A, no: Unit -> A) -> A:
  match b:
    case True{}:
      yes(Unit{})
    case False{}:
      no(Unit{})

def chunk.go(k: Utf8.Dec -> String -> IO(Scan), ds: Utf8.Dec & String) -> IO(Scan):
  (d, t) = ds
  k(d, t)

def chunk(k: File -> Utf8.Dec -> String -> IO(Scan),
  got: File & Result<&1, &1, U32 & String, Utf8.Dec & String>) -> IO(Scan):
  (f, r) = got
  IO.bind(Utf8.Dec & String, Scan, IO.pass(Utf8.Dec & String, r), chunk.go(k(f)))

def stream(fuel: Nat, f: File, dec: Utf8.Dec, +max: U32, st: Scan) -> IO(Scan):
  match fuel:
    case 0n:
      IO.die(Scan, 1, "io_stream: out of fuel")
    case 1n+left:
      IO.bind(File & Result<&1, &1, U32 & String, Utf8.Dec & String>, Scan,
        File.read_text(f, dec, max), chunk(g => d => text =>
          +nd = d
          +ns = Scan.text(text, st)
          choose(File -> IO(Scan), Utf8.Dec.eof(nd),
            u => h => IO.bind(Unit, Scan, File.close(h), v => IO.pure(Scan, ns)),
            u => h => stream(left, h, nd, max, ns))(g)))

def whole.go(read: File & Result<&1, &1, U32 & String, String>) -> IO(Unit):
  (f, r) = read
  do IO<Unit>:
    s : String <- IO.pass(String, r)
    File.close(f)
    IO.print(Scan.show(Scan.text(s, Scan{2166136261, 0, 0, True{}})))

def whole(+path: String) -> IO(Unit):
  do IO<Unit>:
    f : File <- IO.try(File, File.open(path, "r"))
    read : File & Result<&1, &1, U32 & String, String> <- File.read(f, 1048576)
    whole.go(read)

def chunked(+path: String, max: U32) -> IO(Unit):
  do IO<Unit>:
    f : File <- IO.try(File, File.open(path, "r"))
    st : Scan <- stream(4000n, f, Utf8.Dec.new(), max, Scan{2166136261, 0, 0, True{}})
    IO.print(Scan.show(st))

def wrote(w: File & Result<&1, &1, U32 & String, Unit>) -> IO(Unit):
  (f, r) = w
  do IO<Unit>:
    IO.pass(Unit, r)
    File.close(f)

def each(+path: String) -> IO(Unit):
  do IO<Unit>:
    whole(path)
    chunked(path, 1)
    chunked(path, 2)
    chunked(path, 3)
    chunked(path, 7)
    chunked(path, 4096)

def main() -> IO(Unit):
  do IO<Unit>:
    f : File <- IO.try(File, File.open("/tmp/bend_strings_io_stream", "w"))
    w : File & Result<&1, &1, U32 & String, Unit> <-
      File.write(f, String.repeat("añ€😀 wörd\n", 200n))
    wrote(w)
    g : File <- IO.try(File, File.open("/tmp/bend_strings_io_bytes", "w"))
    w : File & Result<&1, &1, U32 & String, Unit> <- File.write_bytes(g,
      [239, 187, 191, 65, 0, 240, 159, 152, 128, 192, 128, 237, 160, 128,
       244, 144, 128, 128, 226, 130])
    wrote(w)
    each("/tmp/bend_strings_io_bytes")
    each("/tmp/bend_strings_io_stream")

#|3845243302 14 chars 1 words
#|3845243302 14 chars 1 words
#|3845243302 14 chars 1 words
#|3845243302 14 chars 1 words
#|3845243302 14 chars 1 words
#|3845243302 14 chars 1 words
#|1939504133 2000 chars 400 words
#|1939504133 2000 chars 400 words
#|1939504133 2000 chars 400 words
#|1939504133 2000 chars 400 words
#|1939504133 2000 chars 400 words
#|1939504133 2000 chars 400 words
