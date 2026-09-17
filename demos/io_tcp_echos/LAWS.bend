# The laws of the echo server. They pin echo_step, its pure part: the
# move the handler makes on each recv. PROOF.bend must prove them.
import Base
import ./main.bend as Echo

# LAW: data is sent back as it came, byte for byte.
law echoes_data:
  for +c: Char
  for +t: String
  {Echo.echo_step(Done{SCon{c, t}}) == Some{SCon{c, t}} : Maybe<String>}

# LAW: a closed peer (an empty recv) or a failed recv ends the
# connection: nothing is sent.
law closes_on_end:
  for e: U32 & String
  {Echo.echo_step(Done{""}) == None{} : Maybe<String>} & {Echo.echo_step(Fail{e}) == None{} : Maybe<String>}
