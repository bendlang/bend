# regression witness: shared sum layouts must not expand into a tree to print main.
import Base

type Choice<-A: Data> is Data:
  ChooseLeft{value: A}
  ChooseRight{value: A}

type Answer is Data:
  Ready{value: U32}
  Again{value: Answer}
  Other{value: Choice<Choice<Choice<Choice<Choice<Choice<Choice<Choice<Choice<Choice<Choice<Choice<Choice<Choice<Choice<Choice<Choice<Choice<Choice<Choice<Choice<Choice<Choice<Choice<U32>>>>>>>>>>>>>>>>>>>>>>>>}

def main() -> Answer:
  Ready{42}

#|Ready{42}
