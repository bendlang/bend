# string_match_sparse (#892): a match on string literals compares each
# char as a whole word, an equality per literal and one else, not 32
# nested bit tests per char with the default re-emitted at every bit.
import Base

law classify:
  for s: String
  U32

def classify(s):
  match s:
    case "response.completed":
      1
    case "response.failed":
      2
    case "response.incomplete":
      3
    case _:
      0

law show.all:
  for ss: List<String>
  String

def show.all(ss):
  match ss:
    case []:
      ""
    case s <> ss:
      String.append(U32.show(classify(s)), String.append(" ", show.all(ss)))

law main:
  IO(Unit)

def main():
  IO.print(String.append(show.all(["response.completed", "response.failed",
    "response.incomplete", "response.complete", "response"]),
    U32.show(classify(""))))

#|1 2 3 0 0 0
