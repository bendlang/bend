# Invalid schemes, header injection, and absent bounds must not reach the network.
import Base

def invalid(result: Result<&1, &1, U32 & String, HTTP.Response>) -> Bool:
  match result:
    case Fail{(code, message)}:
      U32.is_eq(code, 22)
    case Done{response}:
      False{}

def main() -> IO(Unit):
  do IO<Unit>:
    scheme : Result<&1, &1, U32 & String, HTTP.Response> <- HTTP.request("GET", "file:///etc/passwd", [], "", 1024, 1000, "")
    a : Unit <- IO.print(Bool.show(invalid(scheme)))
    header : Result<&1, &1, U32 & String, HTTP.Response> <- HTTP.request("GET", "http://127.0.0.1/", [Header{"X-Name", "ok\r\nX-Evil: yes"}], "", 1024, 1000, "")
    b : Unit <- IO.print(Bool.show(invalid(header)))
    method : Result<&1, &1, U32 & String, HTTP.Response> <- HTTP.request("GET\nX-Evil", "http://127.0.0.1/", [], "", 1024, 1000, "")
    c : Unit <- IO.print(Bool.show(invalid(method)))
    output : Result<&1, &1, U32 & String, HTTP.Response> <- HTTP.request("GET", "http://127.0.0.1/", [], "", 0, 1000, "")
    d : Unit <- IO.print(Bool.show(invalid(output)))
    time : Result<&1, &1, U32 & String, HTTP.Response> <- HTTP.request("GET", "http://127.0.0.1/", [], "", 1024, 0, "")
    e : Unit <- IO.print(Bool.show(invalid(time)))
    head_body : Result<&1, &1, U32 & String, HTTP.Response> <- HTTP.request("HEAD", "http://127.0.0.1/", [], "not empty", 1024, 1000, "")
    IO.print(Bool.show(invalid(head_body)))

#|True
#|True
#|True
#|True
#|True
#|True
