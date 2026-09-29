# P16 program completion after ordinary and live-instance checking

Prospective design: design/phase16/program-completion.md (root frozen).
Parent wave7-source-01/project. Scope diagnostic/produce.bend, driver/api.bend,
and typed-driver.mjs only. Six existing declaration workers carry an explicit
completion Boolean; existing public diagnostic APIs pass true. New three-arg
check_program_diagnostic passes false, retains ordinary failure, specializes,
then counts source-book TODOs once and returns a materialized DResult book.
ABI2 host routing skips old completion/specializer and refuses missing/unknown
capability. Existing ABI0/1 routes stay intact. No semantic kernel changes.

Preserve program-completion-baseline01: four new fixtures accidentally used bare
? and do not exercise holes. Fresh controls02 use ?TODO; all other baseline rows
were inspected and their intended parse/check stages agree. Retain same-body
instance-versus-ordinary diagnostic disagreement as an explicit known gap.
Run frozen corrected baseline, checked B1/focus, paired controls and old public
checker API/materialized-instance controls on CPU3. Root independently owns ABI
routing controls, full-corpus/cost/promotion. No complete chronology claim.
