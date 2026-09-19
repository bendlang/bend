# Shared descriptors and overlapping views must detach before writing.
# copy releases the large payload owner; the runtime probe checks its counts.
import Base

def identity(~A: Data, x: A) -> A:
  x

def reuse(+s: String) -> List<&2, String>:
  +a = String.slice(s, 1n, 5n)
  +b = String.slice(s, 2n, 6n)
  [s, a, b, String.to_upper(a), String.reverse(b),
   SCon{'!', a}, String.append(b, "?"), s, a, b]

def tail(s: String) -> String:
  match s:
    case SNil{}:
      ""
    case SCon{h, t}:
      SCon{h, t}

def main() -> List<&2, String> & (List<&2, String> & (String & String)):
  +s = String.from_list(['a', 'b', 'c', 'd', 'e', 'f'])
  +tiny = String.slice(String.repeat("abcdef", 128n), 2n, 5n)
  +box = {[identity(~String, s), "static"] : List<&2, String>}
  (reuse(s),
   ([String.reverse(String.copy(s)), String.to_upper("static"),
     String.to_lower(String.to_upper(s)), tail(s), String.join(box, "/"),
     String.join(box, "/"), String.copy(tiny), tiny, String.append(s, s),
     String.append(String.slice(s, 1n, 5n), String.slice(s, 2n, 6n))],
    String.clone(identity(~String, String.append(s, "!")))))

#|(["abcdef", "bcde", "cdef", "BCDE", "fedc", "!bcde", "cdef?", "abcdef", "bcde", "cdef"], ["fedcba", "STATIC", "abcdef", "abcdef", "abcdef/static", "abcdef/static", "cde", "cde", "abcdefabcdef", "bcdecdef"], "abcdef!", "abcdef!")
