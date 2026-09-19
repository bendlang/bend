# Width counts code points.
import Base

def main() -> List<&2, String>:
  [String.pad_start("ab", 1n, '.'), String.pad_start("ab", 2n, '.'),
   String.pad_start("ab", 4n, '.'), String.pad_end("ab", 1n, '.'),
   String.pad_end("ab", 2n, '.'), String.pad_end("ab", 4n, '.'),
   String.pad_start("", 2n, '😀'), String.pad_end("😀", 3n, 'é'),
   String.pad_start("e\u{301}", 3n, '\0'),
   String.zfill("-42", 2n), String.zfill("-42", 3n), String.zfill("-42", 6n),
   String.zfill("+7", 4n), String.zfill("-", 3n), String.zfill("+", 1n),
   String.zfill("", 0n), String.zfill("", 3n), String.zfill("😀", 3n),
   String.zfill("a-1", 5n), String.zfill("−2", 4n),
   String.capitalize(""), String.capitalize("hELLO wORLD"),
   String.capitalize("😀ABC"), String.capitalize("éABC"), String.capitalize("\nABC")]

#|["ab", "ab", "..ab", "ab", "ab", "ab..", "😀😀", "😀éé", "\0é", "-42", "-42", "-00042", "+007", "-00", "+", "", "000", "00😀", "00a-1", "00−2", "", "Hello world", "😀abc", "éabc", "\nabc"]
