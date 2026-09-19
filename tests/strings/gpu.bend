# Shared string descriptors and overlapping payload views cross a ! transfer.
import Base

def work(+s: String) -> String:
  String.append(String.reverse(String.to_upper(s)), s)

def native.parts(+s: String, parts: String & (String & String)) -> List<&2, String> & (List<&2, Maybe<&2, Nat>> & (Nat & U32)):
  (before, (sep, after)) = parts
  ([String.replace(s, "aa", "$&aa"), String.join(String.split_on(s, "::"), "/"),
    before, sep, after, String.join(String.splitlines(s), "|"),
    String.pad_start(s, 18n, '😀'), String.pad_end(s, 18n, '.'),
    String.zfill("-42", 5n), String.capitalize(s)],
   ([String.find(s, "aaab"), String.find_last(s, "aa"), String.find_last(s, ""),
     String.find(s, "absent")], (String.count(s, "aa"), String.hash(s))))

def native(+s: String) -> List<&2, String> & (List<&2, Maybe<&2, Nat>> & (Nat & U32)):
  native.parts(s, String.partition(s, "::"))

def main() -> (String & (String & String)) &
  ((List<&2, String> & (List<&2, Maybe<&2, Nat>> & (Nat & U32))) &
   (List<&2, String> & (List<&2, Maybe<&2, Nat>> & (Nat & U32)))):
  +s = String.from_list(['a', 'b', '😀', 'c', 'd'])
  a b = work!(s) work!(String.slice(s, 1n, 4n))
  +text = String.append(String.repeat("a", 5n), "b::x😀::y\r\n")
  c d = native!(text) native!(String.slice(text, 1n, 16n))
  ((a, (b, s)), (c, d))

#|(("DC😀BAab😀cd", "C😀Bb😀c", "ab😀cd"), (["$&aa$&aaab::x😀::y\r\n", "aaaaab/x😀/y\r\n", "aaaaab", "::", "x😀::y\r\n", "aaaaab::x😀::y", "😀😀😀aaaaab::x😀::y\r\n", "aaaaab::x😀::y\r\n...", "-0042", "Aaaaab::x😀::y\r\n"], [Some{2n}, Some{3n}, Some{15n}, None{}], 2n, 2264192787), ["$&aa$&aab::x😀::y\r\n", "aaaab/x😀/y\r\n", "aaaab", "::", "x😀::y\r\n", "aaaab::x😀::y", "😀😀😀😀aaaab::x😀::y\r\n", "aaaab::x😀::y\r\n....", "-0042", "Aaaab::x😀::y\r\n"], [Some{1n}, Some{2n}, Some{14n}, None{}], 2n, 130572590)
