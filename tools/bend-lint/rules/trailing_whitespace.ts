// style/trailing-whitespace: spaces or tabs at the end of a line. The fix
// deletes them, so it is safe.

import type { LintRule } from "../src/lint.ts";
import { lines } from "./shared.ts";

// Constants
// =========

export const rules: LintRule[] = [{
  id: "style/trailing-whitespace",
  run: (cx) => lines(cx.root.file).flatMap(({ text, end }) => {
    const width = text.length - text.trimEnd().length;
    const spn = { file: cx.root.file, beg: end - width, end };
    return width === 0 ? [] : [cx.diag({
      message: "Remove the whitespace at the end of the line.",
      severity: "warning", spn,
      fixes: [{ title: "Remove trailing whitespace", applicability: "safe", edits: [{ spn, text: "" }] }],
    })];
  }),
}];
