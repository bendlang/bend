// Loads rule modules. A module default-exports an array of rules.

import * as path from "node:path";
import * as url from "node:url";

import { validRule } from "./lint.ts";
import type { LintRule } from "./types.ts";

export async function loadRules(files: string[]): Promise<LintRule[]> {
  const rules: LintRule[] = [];
  for (const file of files) {
    if (file.endsWith(".bend")) {
      throw new Error(file + ": rules written in Bend are not supported yet");
    }
    const { default: loaded } = await import(url.pathToFileURL(path.resolve(file)).href);
    if (!Array.isArray(loaded)) {
      throw new Error(file + " must default-export an array of rules");
    }
    for (const rule of loaded) {
      if (!validRule(rule)) {
        throw new Error(file + " has an invalid rule (needs an id like ns/name and a run function)");
      }
      rules.push(rule);
    }
  }
  return rules;
}
