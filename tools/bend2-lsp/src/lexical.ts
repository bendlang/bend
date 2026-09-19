import type { AnalysisDiagnostic } from "./protocol.js";

type LexicalDiagnostic = Omit<AnalysisDiagnostic, "uri">;

export function lexicalDiagnostics(source: string): LexicalDiagnostic[] {
  const diagnostics: LexicalDiagnostic[] = [];
  const opens: Array<{ char: string; at: number }> = [];
  const closeFor: Record<string, string> = { "(": ")", "[": "]", "{": "}" };
  let quote = "";
  let quoteAt = 0;
  let escaped = false;
  for (let i = 0; i < source.length; i++) {
    const c = source[i];
    if (quote) {
      if (escaped) escaped = false;
      else if (c === "\\") escaped = true;
      else if (c === quote) quote = "";
      else if (c === "\n") {
        diagnostics.push({ range: { start: quoteAt, end: i }, message: `Unterminated ${quote === '"' ? "string" : "character"} literal.`, code: "parsing" });
        quote = "";
      }
      continue;
    }
    if (c === "#") {
      const end = source.indexOf("\n", i);
      i = end < 0 ? source.length : end - 1;
      continue;
    }
    if (c === '"' || c === "'") {
      quote = c;
      quoteAt = i;
      continue;
    }
    if (c in closeFor) opens.push({ char: c, at: i });
    else if (c === ")" || c === "]" || c === "}") {
      const open = opens.at(-1);
      if (!open || closeFor[open.char] !== c) {
        diagnostics.push({ range: { start: i, end: i + 1 }, message: `Unmatched '${c}'.`, code: "parsing" });
      } else opens.pop();
    }
  }
  if (quote) diagnostics.push({ range: { start: quoteAt, end: source.length }, message: `Unterminated ${quote === '"' ? "string" : "character"} literal.`, code: "parsing" });
  for (const open of opens) diagnostics.push({ range: { start: open.at, end: open.at + 1 }, message: `Unclosed '${open.char}'.`, code: "parsing" });
  for (const match of source.matchAll(/\?TODO\b/g)) {
    diagnostics.push({ range: { start: match.index, end: match.index + match[0].length }, message: "Unresolved hole '?TODO'.", code: "holes" });
  }
  return diagnostics;
}

const STATIC_HOVERS: Record<string, string> = {
  def: "Declares a top-level function.", type: "Declares an algebraic datatype.", law: "Declares a proposition that must be proved.",
  match: "Pattern-matches one or more values.", case: "Introduces a match case.", do: "Sequences IO operations.", return: "Returns from a `do` block.",
  for: "Introduces a universally quantified law variable.", exs: "Introduces an existential law variable.", where: "Adds a proposition to a law binder.",
  import: "Imports Base or a namespaced `.bend` file.", Type: "The universe of unrestricted types.", Data: "The universe of affine data.", Kind: "A quantity-indexed type universe.", Quant: "The type of quantities.",
  "->": "Function type or return-type separator.", "=>": "Lambda body separator.", "==": "Propositional equality.", "!=": "Negated equality.", "<&>": "Quantity minimum.",
  "&0": "Erased quantity.", "&1": "Affine quantity.", "&2": "Unrestricted quantity.", "{==}": "Reflexivity proof.", "%": "Equality rewrite.", "!": "Runs a parallel call on the GPU when available.",
};

export function staticHover(token: string): string | null {
  const text = STATIC_HOVERS[token];
  return text ? `**${token}**\n\n${text}` : null;
}
