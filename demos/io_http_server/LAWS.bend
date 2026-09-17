# The laws of the HTTP server. They pin http_response, its pure part:
# the bytes sent for a page. PROOF.bend must prove them.
import Base
import ./main.bend as Srv

# LAW: the response of any page is some head, then a blank line, then
# the page: a client that cuts at the blank line reads the page back.
law page_after_blank:
  for +page: String
  exs head: String
  {head ++ ("\r\n\r\n" ++ page) == Srv.http_response(page) : String}

# LAW: the response determines the page: two equal responses come
# from equal pages.
law response_inj:
  for +a: String
  for +b: String
  for  e: {Srv.http_response(a) == Srv.http_response(b) : String}
  {a == b : String}
