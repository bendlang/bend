# Specification helpers for LAWS.bend, not part of the editable program.
# Keep this file and LAWS.bend unchanged when rewriting main.bend or PROOF.bend.

import Base

# the head of a response: the status line and the headers. It holds no
# blank line, so the first blank line of a response is the one before
# the page.
def head() -> String:
  "HTTP/1.1 200 OK\r\nContent-Type: text/html\r\nConnection: close"
