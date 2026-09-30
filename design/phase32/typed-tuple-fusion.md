# Typed private Array.get consumer bridge

Prospective production mechanism after the saved-output ablation. Root owns the
emitter; only implement if the separate tuple experiment survives its gates.
The original private helper remains available for all other producers.

The bounded region planner already proves arguments and native dependencies.
At a fully saturated private call, inspect its final proved argument and the
completed helper in the current region. Require a canonical JNative Array.get
with its complete erased-U32/array/index argument vector. Require that the
helper's complete transformed body is a JUnpack of its final ordinary parameter,
with two fields and the canonical Array<U32>/U32 Sigma input type. Nonmatching
shapes remain ordinary JCall. Use an explicit private node for the admitted
bridge call; do not infer this transformation from printed JavaScript names.

Emit a private bridge in the same lexical region, with an injective suffix on
the existing encoded helper identity. Its parameters are the preceding ordinary
helper arguments followed by the original erased slot, array and index. The
call evaluates all arguments once and in the same order. The bridge captures
the array in the old first field slot, executes exactly Array.get's arraydata,
Number conversion, modulo and indexed read, captures that scalar in the second
field slot, then emits the original proved arm. It does not construct the
temporary Sigma, change storage, drop unused reads, or alter the public helper.
No shared-runtime change or general tuple ABI is required.

Ordinary helper inputs map to distinct positional slots; unpack fields start
after all inputs. The removed tuple parameter has no source binder inside its
pattern arm. Nested blocks and parallel lets retain the existing emitter rules.
Initial-zero Nat rebinding remains outside this transformation. Region limits,
fully demanded returns, canonical layout and stable native root guards remain
unchanged. A bridge may be emitted for an eligible helper without a matching
producer; measure the resulting code-size cost rather than ignoring it.

Test actual checked emissions against the saved derivative, independent fold,
full arrays and logical native-event stream. Add earlier-argument writes,
consumer writes before use, unused fields, wrapped indices, repeated gets,
shared handles, generated-name collisions and noncanonical refusal controls.
Instrument the actual replacement read for event comparison, separately from
tuple allocation. Preserve ablations for statements alone and fusion alone;
compare actual selected output before combining speed claims. Track new Bend
lines/concepts and normal compilation cost along with generated execution time.
