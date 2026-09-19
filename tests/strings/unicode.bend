# Code points include combining marks and NUL; trim/case are ASCII-only.
import Base

def main() -> List<&2, String> & (List<&2, Nat> & (List<&2, Char> & List<&2, Bool>)):
  ([String.trim(" \t\n\r\u{b}\u{c}a \t\n\r\u{b}\u{c}"),
    String.trim_start(" \tA \t"), String.trim_end(" \tA \t"),
    String.trim("\u{a0}x\u{a0}"), String.to_upper("éßıa"),
    String.to_lower("ÉİAZ"), String.reverse("e\u{301}😀\0"),
    String.join(String.split("😀a😀😀b😀", '😀'), "/"),
    String.join(String.lines("a\nb\n"), "/")],
   ([String.length(""), String.length("A😀é"), String.length("e\u{301}"),
     String.length("a\0b")],
    (String.to_list("A😀é\0"),
     [String.starts_with("😀éx", "😀é"), String.ends_with("x😀é", "😀é"),
      String.starts_with("a", "ab"), String.ends_with("a", "ba"),
      String.starts_with("", ""), String.ends_with("", ""),
      String.is_lt("\u{e000}", "😀"), String.is_gt("😀", "\u{e000}"),
      String.is_le("😀", "😀"), String.is_ge("😀", "😀")])))

#|(["a", "A \t", " \tA", " x ", "éßıA", "Éİaz", "\0😀́e", "/a//b/", "a/b/"], [0n, 3n, 2n, 3n], ['A', '😀', 'é', '\0'], [True{}, True{}, False{}, False{}, True{}, True{}, True{}, True{}, True{}, True{}])
