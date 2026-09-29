# Counter worker interface correction, before attempt02

Attempt01 remains failed. It passed the ES module namespace to the unchanged
host API injection, but this generated API exports compiler functions through
its default object. The host correctly refused with `api.f_parse is not a
function`, and the full result equality assertion failed. No census was valid.

Version02 uses module.default for inspect and the named module counter getter.
It also saves the complete observed result before assertions so a further
failure remains directly inspectable. All instrumentation, comparison rules,
source/cache identities, affinity and resource limits stay unchanged. New
worker, runner and output names preserve the consumed first attempt.
