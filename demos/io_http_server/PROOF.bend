# The proofs of the HTTP server laws. http_response(page) unfolds to
# the 63 characters of its head in front of the page: page_after_blank
# names the head and computes; response_inj drops those 63 characters
# from both responses (Equal.cong), which leaves the pages.
import Base
import ./main.bend as Srv
import ./LAWS.bend as Laws

def Laws.page_after_blank(page):
  ("HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close", {==})

# the text after its first n characters
def drop(n: Nat, s: String) -> String:
  match n:
    case 0n:
      s
    case 1n+p:
      match s:
        case SNil{}:
          SNil{}
        case SCon{h, t}:
          drop(p, t)

def Laws.response_inj(a, b, e):
  Equal.cong(String, String, s => drop(63n, s), Srv.http_response(a), Srv.http_response(b), e)
