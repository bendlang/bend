# Additive diagnostic data. These types do not change the trusted kernel IR.
# Context entries are kernel Bind terms, innermost first. Source offsets use
# UTF-16 units, matching upstream Span. Origins are optional and never guessed.
type DExpr is Data:
  DText{+text: String}
  DTerm{+term: KTerm}

type DSpan is Data:
  DNoSpan{}
  DSpan{+source: String, begin: U32, end: U32}

type DOrigin is Data:
  DSourceOrigin{+source: String, begin: U32, end: U32}

type DDiagnostic is Data:
  DDiagnostic{+expected: DExpr, +observed: DExpr, has_observed: Bool, +context: List<&2, KTerm>, +definition: String, +span: DSpan, +note: String, +trail: List<&2, KTerm>}

type DResult is Data:
  DResult{+error: String, +book: List<&2, KDef>, +diagnostic: DDiagnostic}
