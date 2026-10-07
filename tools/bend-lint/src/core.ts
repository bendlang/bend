// The instrumented bend2/bend.ts. Every bend-lint module gets Bend from
// here, so the patch is in place before bend.ts loads.

import { loadBend, type Bend as BendT } from "./instrument.ts";

export const Bend: BendT = await loadBend();
