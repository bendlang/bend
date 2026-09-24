# RFC 8259 JSON round trips, surrogate pairs, malformed syntax, and forged values.
import Base

def text_encoded(encoded: Result<&1, &1, U32 & String, String>) -> String:
  match encoded:
    case Done{value}:
      value
    case Fail{(position, message)}:
      "invalid encoding: " ++ message

def text(result: Result<&1, &1, U32 & String, JSON>) -> String:
  match result:
    case Done{value}:
      text_encoded(JSON.write(value))
    case Fail{(position, message)}:
      "invalid"

def main() -> IO(Unit):
  do IO<Unit>:
    v0 : Unit <- IO.print(text(JSON.read("{\"text\":\"Привет\",\"n\":12.50,\"items\":[true,null]}")))
    v1 : Unit <- IO.print(text(JSON.read("[]")))
    v2 : Unit <- IO.print(text(JSON.read("{}")))
    v3 : Unit <- IO.print(text(JSON.read(" [ 1, 2 , false ] ")))
    v4 : Unit <- IO.print(text(JSON.read("\"\\uD83D\\uDE00\"")))
    v5 : Unit <- IO.print(text(JSON.read("{\"s\":\"a\\nb\"}")))
    v6 : Unit <- IO.print(text(JSON.read("-0")))
    v7 : Unit <- IO.print(text(JSON.read("1e+3")))
    b0 : Unit <- IO.print(text(JSON.read("")))
    b1 : Unit <- IO.print(text(JSON.read("01")))
    b2 : Unit <- IO.print(text(JSON.read("1.")))
    b3 : Unit <- IO.print(text(JSON.read("-.1")))
    b4 : Unit <- IO.print(text(JSON.read("[1,]")))
    b5 : Unit <- IO.print(text(JSON.read("{\"a\":}")))
    b6 : Unit <- IO.print(text(JSON.read("{\"a\" 1}")))
    b7 : Unit <- IO.print(text(JSON.read("nullx")))
    b8 : Unit <- IO.print(text(JSON.read("\"\\x\"")))
    b9 : Unit <- IO.print(text(JSON.read("\"\\uD800\"")))
    b10 : Unit <- IO.print(text(JSON.read("\"raw\nline\"")))
    b11 : Unit <- IO.print(text(JSON.read("[1] true")))
    b12 : Unit <- IO.print(text(JSON.read("true false")))
    b13 : Unit <- IO.print(text(JSON.read("\"\\uDE00\"")))
    b14 : Unit <- IO.print(text(JSON.read("\"\\uD83D\\u0041\"")))
    b15 : Unit <- IO.print(text(JSON.read("\"\\uD83Da\"")))
    large : Unit <- IO.print(text(JSON.read("123456789012345678901234567890")))
    bad_field : Unit <- IO.print(text_encoded(JSON.write(Obj{[Num{"1"}]})))
    bad_member : Unit <- IO.print(text_encoded(JSON.write(Member{"x", Num{"1"}})))
    IO.print(text_encoded(JSON.write(Num{"01"})))

#|{"text":"Привет","n":12.50,"items":[true,null]}
#|[]
#|{}
#|[1,2,false]
#|"😀"
#|{"s":"a\nb"}
#|-0
#|1e+3
#|invalid
#|invalid
#|invalid
#|invalid
#|invalid
#|invalid
#|invalid
#|invalid
#|invalid
#|invalid
#|invalid
#|invalid
#|invalid
#|invalid
#|invalid
#|invalid
#|123456789012345678901234567890
#|invalid encoding: object field is not a member
#|invalid encoding: member outside an object
#|invalid encoding: invalid number lexeme
