# Array.get_unchecked on a boxed element hands it out shared, like
# Array.get: the same cell read twice, and read again by Array.get after,
# still holds its value
import Base

def mk() -> Array<String>:
  Array.set(String, Array.set(String, Array.set(String,
    Array.set(String, ["" : String*4n], 0, "a"), 1, "b"), 2, "c"), 3, "d")

def then(r: Array<String> & String, k: Array<String> -> String -> String) -> String:
  match r:
    case Tuple{a, s}:
      k(a, s)

@unsafe
def main() -> IO(Unit):
  IO.print(
    then(Array.get_unchecked(String, mk(), 3), a => w =>
      then(Array.get_unchecked(String, a, 3), b => x =>
        then(Array.get_unchecked(String, b, 0), c => y =>
          then(Array.get(String, c, 3), d => z =>
            String.append(w, String.append(x, String.append(y, z))))))))

#|ddad
