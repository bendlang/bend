# laws: reverse is an involution; split/join and cut reconstruct the input;
# the end-relative windows clamp (get_end: 0 and past-the-start are None);
# slice is [i,j) clamped; split_on and partition are total (empty separator
# never matches); splitlines drops only the trailing empty
import Base

def fox() -> String:
  "the quick brown fox"

def glue(ab: String & String) -> String:
  (a, b) = ab
  String.append(a, b)

def main() -> (Bool & (Bool & Bool)) & ((String & (String & (Maybe<&2, Char> & (Maybe<&2, Char> & Maybe<&2, Char>)))) & ((String & String) & ((List<&2, String> & (List<&2, String> & List<&2, String>)) & ((String & (String & String)) & ((String & (String & String)) & (List<&2, String> & List<&2, String>)))))):
  +s = fox()
  ((String.eq(String.reverse(String.reverse(s)), s),
    (String.eq(String.join(String.split(s, ' '), " "), s),
     String.eq(glue(String.cut(s, 4n)), s))),
   ((String.take_end(s, 3n),
     (String.drop_end(s, 4n),
      (String.get_end(s, 1n), (String.get_end(s, 0n), String.get_end("ab", 3n))))),
    ((String.slice(s, 4n, 9n), String.slice(s, 10n, 100n)),
     ((String.split_on("a,,b", ","), (String.split_on("ab", "ab"), String.split_on("ab", ""))),
      ((String.partition("k=v=w", "="),
        (String.partition("kv", "="),
         (String.splitlines("a\r\nb\n\nc\n"), String.splitlines("")))))))))

#|((True{}, True{}, True{}), ("fox", "the quick brown", Some{'x'}, None{}, None{}), ("quick", "brown fox"), (["a", "", "b"], ["", ""], ["ab"]), ("k", "=", "v=w"), ("kv", "", ""), ["a", "b", "", "c"], [])
