# Constructor controls: prospective immutable-data boundary

Before any probe execution, root clarified that the helper accepts immutable KDef/List data. The original34-case fixture file and unconsumed first tool version remain preserved. Version2 separates exact raw getter equivalence from the meaningful immutable-data gate.

Raw results, independent expected outcomes, every getter event and total reads remain unchanged and may fail. For the scoped gate, require identical return/throw payload and reference identity, independent expected outcome success, and identical event order after removing only additional reads of an already-read list tag. The read-count delta must equal those explicitly listed removals. Every other new field/subtree read or changed exception order fails. The wide case has no event log and therefore requires exact reads; the deep cases now log events to make classification explicit.

The single prospective second-read-poison case violates immutable tag semantics. Exclude it only from the scoped semantic decision, retaining its full raw failure and exact comparison. All other poison cases still guard first-error order or previously undemanded fields. The tool exit verdict follows the scoped gate and reports rawExactPass separately; no arbitrary effectful-getter equivalence is claimed.
