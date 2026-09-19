# Split preserves empties; words and splitlines have their own boundary sets.
import Base

def main() -> List<&2, List<&2, String>> & List<&1, String & (String & String)>:
  ([String.split("", ','), String.split(",a,,b,", ','),
    String.split("😀a😀", '😀'), String.split_on("", ""),
    String.split_on("abc", ""), String.split_on("", "::"),
    String.split_on("::a::::b::", "::"), String.split_on("aaaaa", "aa"),
    String.split_on("abc", "abcd"), String.split_on("😀a😀😀", "😀"),
    String.words(" \ta\nb\u{b}c\u{c}d\re f \t"),
    String.words(""), String.words(" \t\r\n\u{b}\u{c}"),
    String.words("a\u{a0}b\u{85}c\u{2028}d"),
    String.lines("a\r\nb\n"), String.splitlines("a\r\nb\n"),
    String.lines(""), String.splitlines(""), String.splitlines("\n\n"),
    String.splitlines("a\nb\rc\r\nd\u{b}e\u{c}f\u{1c}g\u{1d}h\u{1e}i\u{85}j\u{2028}k\u{2029}"),
    String.splitlines("a\t\0b\u{1f}c"), String.splitlines("\r\n\rX")],
   [String.partition("k=v=w", "="), String.partition("kv", "="),
    String.partition("kv", ""), String.partition("", ""),
    String.partition("", "x"), String.partition("abc", "abc"),
    String.partition("=a", "="), String.partition("a=", "="),
    String.partition("😀a😀b", "😀")])

#|([[""], ["", "a", "", "b", ""], ["", "a", ""], [""], ["abc"], [""], ["", "a", "", "b", ""], ["", "", "a"], ["abc"], ["", "a", "", ""], ["a", "b", "c", "d", "e", "f"], [], [], ["a bc d"], ["a\r", "b", ""], ["a", "b"], [""], [], ["", ""], ["a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k"], ["a\t\0b\u{1f}c"], ["", "", "X"]], [("k", "=", "v=w"), ("kv", "", ""), ("kv", "", ""), ("", "", ""), ("", "", ""), ("", "abc", ""), ("", "=", "a"), ("a", "=", ""), ("", "😀", "a😀b")])
