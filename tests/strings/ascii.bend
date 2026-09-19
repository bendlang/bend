# ascii: case mapping is ASCII-only and builds the mapped Chr only in the
# selected branch (to_upper("aZ\n9é") used to throw on JS); capitalize,
# zfill (sign-aware), pad_start/pad_end and words share the ASCII scope
import Base

def main() -> (Bool & String) & (String & (List<&2, String> & (String & String))):
  ((String.eq(String.to_upper("aZ\n9é"), "AZ\n9é"), String.to_lower("aZ9É")),
   (String.capitalize("hELLO wORLD"),
    (String.words(" \ta\nb  c\r\n"),
     (String.pad_end(String.pad_start("ab", 4n, '.'), 6n, '-'),
      String.join([String.zfill("-42", 6n), String.zfill("+1", 1n),
                   String.zfill("7", 3n), String.zfill("", 2n)], ",")))))

#|((True{}, "az9É"), "Hello world", ["a", "b", "c"], "..ab--", "-00042,+1,007,00")
