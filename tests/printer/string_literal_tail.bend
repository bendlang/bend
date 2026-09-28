# a literal prints back as a literal, and a chain that ends in a literal
# prints as one string: SCon{'a', SCon{'b', "cd"}} is "abcd"
import Base

def greet(b: Bool) -> String:
  Bool.pick(String, b, "yes\"\n", "no")

def cons(s: String) -> String:
  SCon{'a', SCon{'b', s}}

def main(b: Bool) -> String:
  String.append(greet(b), cons("cd"))

#|b => String.append(Bool.pick(String, b, "yes\"\n", "no"), "abcd")
