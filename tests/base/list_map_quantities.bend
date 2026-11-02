import Base

type MapTicket is Type:
  MapTicket{value: U32}

def ticket_value(ticket: MapTicket) -> U32:
  match ticket:
    case MapTicket{value}:
      value

def to_ticket(value: U32) -> MapTicket:
  MapTicket{value}

def prefix(value: String) -> String:
  String.append("x", value)

def main() -> IO(Unit):
  +xs : List<&2, U32> = [1, 2, 3]
  +ys : List<&2, U32> = List.map(~&2, ~&2, ~U32, ~U32, ~U32.inc, xs)
  +words : List<&2, String> = ["a", "b"]
  +mapped : List<&2, String> = List.map(~&2, ~&2, ~String, ~String, ~prefix, words)
  tickets = List.map(~&1, ~&1, ~MapTicket, ~U32, ~ticket_value, [MapTicket{4}, MapTicket{5}])
  # the output's quantity is its own: affine to reusable, and reusable to affine
  +up : List<&2, U32> = List.map(~&1, ~&2, ~MapTicket, ~U32, ~ticket_value, [MapTicket{6}])
  down = List.map(~&2, ~&1, ~U32, ~MapTicket, ~to_ticket, xs)
  back = List.map(~&1, ~&1, ~MapTicket, ~U32, ~ticket_value, down)
  do IO<Unit>:
    IO.print(List.show(~&2, ~U32, ~U32.show, xs))
    IO.print(List.show(~&2, ~U32, ~U32.show, ys))
    IO.print(List.show(~&2, ~U32, ~U32.show, ys))
    IO.print(List.show(~&2, ~String, ~(value => value), words))
    IO.print(List.show(~&2, ~String, ~(value => value), mapped))
    IO.print(List.show(~&2, ~String, ~(value => value), mapped))
    IO.print(List.show(~&1, ~U32, ~U32.show, tickets))
    IO.print(List.show(~&2, ~U32, ~U32.show, up))
    IO.print(List.show(~&2, ~U32, ~U32.show, up))
    IO.print(List.show(~&1, ~U32, ~U32.show, back))
    IO.print(List.show(~&2, ~U32, ~U32.show, xs))
    IO.print(List.show(~&2, ~U32, ~U32.show, List.map(~&2, ~&2, ~U32, ~U32, ~U32.inc, [])))

#|[1, 2, 3]
#|[2, 3, 4]
#|[2, 3, 4]
#|[a, b]
#|[xa, xb]
#|[xa, xb]
#|[4, 5]
#|[6]
#|[6]
#|[1, 2, 3]
#|[1, 2, 3]
#|[]
