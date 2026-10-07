// bend-lint loads books with its own copy of bend2/main.ts book_read. If
// that copy drifts, these repo tests stop agreeing with their expected
// output: "SOME PROOFS FAIL" means the check fails, anything else passes.

import { expect, test } from "bun:test";
import * as fs from "node:fs";
import { fileURLToPath } from "node:url";

import { lint } from "../src/index.ts";

const TESTS = [
  "check/alpha_equivalence",
  "check/assert_plain_fill",
  "check/dependent_telescope",
  "check/beta_ann_body",
  "check/ctor_arity",
  "check/forward_reference",
  "check/hole_todo",
  "check/typed_let_mismatch",
  "import/base_prelude",
  "import/string_literal",
  "import/alias_shadow",
  "import/duplicate_name",
];

for (const name of TESTS) {
  test(name, async () => {
    const file = fileURLToPath(new URL("../../../tests/" + name + ".bend", import.meta.url));
    const first = fs.readFileSync(file, "utf8").match(/^#\|(.*)$/m)![1].trim();
    const res = await lint(file, []);
    expect(res.ok).toBe(first !== "SOME PROOFS FAIL");
  });
}
