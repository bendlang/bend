# First/last starts include overlaps; count consumes nonoverlapping matches.
# Empty needles: first=0, last=length, count=length+1 (committed contracts).
import Base

def main() -> List<&2, Maybe<&2, Nat>> & (List<&2, Nat> & List<&2, Bool>):
  +s = String.append(String.repeat("a", 48n), "b")
  +p = String.append(String.repeat("a", 24n), "b")
  ([String.find("banana", "ana"), String.find_last("banana", "ana"),
    String.find("banana", "nab"), String.find_last("banana", "nab"),
    String.find("banana", ""), String.find_last("banana", ""),
    String.find("", ""), String.find_last("", ""),
    String.find("", "a"), String.find_last("a", "aa"),
    String.find_last("aaaa", "aa"), String.find_last("aaa", "a"),
    String.find("😀a😀a😀", "a😀"), String.find_last("😀a😀a😀", "a😀"),
    String.find("a\0b\0", "\0"), String.find_last("a\0b\0", "\0"),
    String.find(s, p), String.find_last(s, p),
    String.find(s, String.append(String.repeat("a", 24n), "c"))],
   ([String.count("banana", "ana"), String.count("aaaaa", "aa"),
     String.count("abc", ""), String.count("", ""), String.count("", "a"),
     String.count("😀a😀a😀", "a😀"), String.count(s, p)],
    [String.contains("banana", "nan"), String.contains("abc", ""),
     String.contains("abc", "abcd"), String.contains(s, p),
     String.starts_with("banana", "ban"), String.ends_with("na", "nana")]))

#|([Some{1n}, Some{3n}, None{}, None{}, Some{0n}, Some{6n}, Some{0n}, Some{0n}, None{}, None{}, Some{2n}, Some{2n}, Some{1n}, Some{3n}, Some{1n}, Some{3n}, Some{24n}, Some{24n}, None{}], [1n, 2n, 4n, 1n, 0n, 2n, 1n], [True{}, True{}, False{}, True{}, True{}, False{}])
