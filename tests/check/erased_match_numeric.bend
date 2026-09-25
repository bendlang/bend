# bend3's pin that erased numeric switching cannot inspect its
# argument. bend spells the erased arrow as a - binder, and has no
# numeric match-lambda at all: the \{0: ...} key dies at parse before
# erasure is even a question
import Base

law hidden:
  @-x:U32 -> U32

def hidden():
  \{0: 0; (1)}

law main:
  U32

def main():
  hidden(5)

#|Error:
#|- expected : '}'
#|- observed : ':'
#|Location:
#|10 | def hidden():
#|11>|   \{0: 0; (1)}
#|   |      ^
#|12 |
#|exit 1
