# The laws of the HTTP client, on http_body, its pure part. They state
# two facts: a text that starts with a blank line has the rest as its
# body, and the body is a suffix of the text. They do not pin the cut of
# a response with a status line and headers: an http_body that only
# strips a leading blank line satisfies both. PROOF.bend must prove them.
import Base
import ./main.bend as Fetch

# LAW: a text that starts with a blank line ("\r\n\r\n") has the rest
# as its body, whatever the rest is.
law body_after_blank:
  for b: String
  {Fetch.http_body("\r\n\r\n" ++ b) == b : String}

# LAW: the body is a suffix of the text: some prefix, then the body,
# is the text itself.
law body_suffix:
  for +s: String
  exs p: String
  {p ++ Fetch.http_body(s) == s : String}
