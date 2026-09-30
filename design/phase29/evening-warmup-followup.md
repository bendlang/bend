# Prospective evening-program follow-up

Recorded after this case completed in the original transfer window and before
any follow-up execution. The other planned clean campaigns remain unchanged.

The unchanged `test-evening-program` input shows a27.4% median regression in
the original window: Phase27 output0.274290ms, Phase29 output0.349464ms. Both
outputs change markedly inside the timed block. Old second/first-half ratios
are2.17–2.31; candidate ratios are2.18–4.10, with candidate sample medians spanning
0.237845–0.372664ms. First-call medians are12.600ms old and12.367ms candidate.

Hypothesis: the1000ms warmup floor intersects different host compilation/tiering
transitions. This is not established by drift alone, and the original regression
must remain reported. A longer-warm result cannot erase a short-window cost.

After all currently frozen campaigns finish, run this one unchanged case with
the already specified confirmation protocol: all three outputs, five fresh
processes per output in rotating serial order, at least100 calls AND3000ms warmup,
300ms timing target,120s deadline, identical CPU/Node/resource/result controls.
Preserve every sample and both halves. Do not change compiler bytes or inputs.

If a material regression survives the longer window, investigate or reject the
candidate before release. If it disappears while first calls remain comparable,
record the warmup tradeoff explicitly and evaluate the broader measured benefit;
do not claim every program improves under every lifecycle condition.
