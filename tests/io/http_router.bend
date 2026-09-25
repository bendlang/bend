# io pin (io_http_router): bend3's Router ran routes in IO, the
# next-thunk minting a fresh Router from a top-level def (--no-halt
# there, nothing here: the wall fires before any liveness judgment,
# so the pin needs no pragma). bend has no HTTP library and no IO
# driver -- routes dies first on its walled type (Request and
# Response respell as their field tuples; the Router type itself stays
# the walled spelling, it has no bend home; the Router destructure
# rides its own helper, a 0-arg call may not head a destructure).
import Base

law hello:
  for req: String & String & List<&1, (String & String)> & String
  IO(U32 & List<&1, (String & String)> & String)

def hello(req):
  (m, p, hs, b) = req
  IO.pure(U32 & List<&1, (String & String)> & String, (200, [], b))

law routes:
  HTTP.Router

def routes():
  (hello, u => routes())

law status:
  for r: U32 & List<&1, (String & String)> & String
  U32

def status(r):
  (s, hs, b) = r
  s

law main_route:
  for r: HTTP.Router
  IO(U32)

def main_route(r):
  (route, next) = r
  do IO<U32>:
    resp : U32 & List<&1, (String & String)> & String <- route(("GET", "/", [], HTTP.no_body()))
    return status(resp)

law main:
  IO(U32)

def main():
  main_route(routes())

#|Error:
#|- expected : a defined name
#|- observed : HTTP.Router
#|Location: routes
#|19 | law routes:
#|20>|   HTTP.Router
#|   |   ^^^^^^^^^^^
#|21 |
#|exit 1
