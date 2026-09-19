# hash: FNV-1a 32 over four little-endian bytes per code point; vectors
# computed independently in Python (seed 2166136261, prime 16777619)
import Base

def main() -> List<&2, U32>:
  [String.hash(""), String.hash("a"), String.hash("abc"),
   String.hash("hello world"), String.hash("é中😀"),
   String.hash(String.slice("!abc?", 1n, 4n)),
   String.hash(String.concat(["a", "b", "c"])),
   String.hash(String.copy("abc")), String.hash("a\0b")]

#|[2166136261, 4125217764, 4070381781, 3112970261, 3781327616, 4070381781, 4070381781, 4070381781, 1124224166]
