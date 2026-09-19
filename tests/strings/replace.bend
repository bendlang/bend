# Replacements consume nonoverlapping original matches; inserted text is literal.
import Base

def main() -> List<&2, String>:
  [String.replace("", "", ""), String.replace("", "", "x"),
   String.replace("", "a", "x"), String.replace("abc", "", ""),
   String.replace("abc", "", "-"), String.replace("😀é", "", "/"),
   String.replace("aaaaa", "aa", ""), String.replace("aaa", "aa", "b"),
   String.replace("ababa", "aba", "X"), String.replace("aaa", "a", "aa"),
   String.replace("abab", "ab", "zabz"), String.replace("banana", "an", "$&"),
   String.replace("aa", "a", "$1$$$`$'"), String.replace("abc", "abcd", "x"),
   String.replace("x😀x😀", "😀", "é😀"), String.replace("a\0a", "\0", "$&"),
   String.replace("same", "same", "same"), String.replace("a", "a", "")]

#|["", "x", "", "abc", "-a-b-c-", "/😀/é/", "a", "ba", "Xba", "aaaaaa", "zabzzabz", "b$&$&a", "$1$$$`$'$1$$$`$'", "abc", "xé😀xé😀", "a$&a", "same", ""]
