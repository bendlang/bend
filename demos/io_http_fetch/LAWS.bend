# The laws of the HTTP client. They pin http_body, its pure part: the
# cut that strips the status line and the headers off a response.
# PROOF.bend must prove them.
import Base
import ./main.bend as Fetch

# LAW: the text after a blank line is the body, whatever follows it.
law body_after_blank:
  for b: String
  {Fetch.http_body("\r\n\r\n" ++ b) == b : String}

# LAW: the body is a suffix of the text: some prefix, then the body,
# is the text itself.
law body_suffix:
  for +s: String
  exs p: String
  {p ++ Fetch.http_body(s) == s : String}
