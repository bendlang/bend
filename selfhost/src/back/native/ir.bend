# Native code-generation IR. A word is an already evaluated C expression.
# Segments are shared by the CPU trampoline and Metal/CUDA dispatch switch.
type N_WordKind is Data:
  N_W32{}
  N_W64{}
  N_Box{}

type N_Param is Data:
  N_Param{+name: String, +kind: N_WordKind}

type N_Frame is Data:
  N_Direct{}
  N_Frame{+pop: U32, +slots: List<&2, String>}

type N_Segment is Data:
  N_Segment{+name: String, +params: List<&2, N_Param>, +result: U32, +frame: N_Frame, +body: String, +refs: List<&2, String>, +host: Bool, +spin: Bool, +fork: Bool, +bang: Bool}

type N_Constructor is Data:
  N_Constructor{+name: String, +arity: U32, +hot: Bool}

type N_Program is Data:
  N_Program{+segments: List<&2, N_Segment>, +constructors: List<&2, N_Constructor>, +image: List<&2, String>, +requests: String, +declarations: String, +show: String, +pure: Bool}

type N_Emitted is Data:
  N_Emitted{+code: String, +value: String, +fresh: U32}
