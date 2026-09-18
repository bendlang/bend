import * as Bend from "../bend.ts";
import * as Comp from "../comp.ts";
import { writeFileSync } from "./platform.ts";

self.onmessage = async (event: MessageEvent) => {
  const { id, source, action } = event.data;
  const start = performance.now();
  try {
    if (typeof source !== "string" || !(["interpret", "compile-run", "compile-js", "compile-c"].includes(action))) {
      throw new Error("Invalid playground action.");
    }
    writeFileSync("/main.bend", source);
    const book = Bend.book_nil();
    await Bend.book_load(book, "/main.bend", "", new Map());
    Bend.book_valid(book);
    const holes = book.hols + book.open;
    if (holes) throw new Error(`${holes} unfinished TODO${holes === 1 ? "" : "s"}. Complete the program before compiling.`);
    const main = book.tlds.main;
    if (!main || main.$ !== "Def") throw new Error("Define a main function to compile this program.");
    let output: string;
    if (action === "interpret") {
      if (Comp.io_type(book) !== null) {
        throw new Error("The kernel interpreter evaluates pure main results. IO programs use the JavaScript runtime; choose Compile to JS and run.");
      }
      if (main.v === null) throw new Error("The interpreter needs a defined main body.");
      const value = Bend.term_snf(book, main.v);
      output = Bend.term_show(Bend.term_lower(value)) + "\n";
      if (output.length > 1024 * 1024) output = output.slice(0, 1024 * 1024) + "\n[Output truncated at 1 MiB.]\n";
    } else {
      output = action === "compile-c" ? Comp.compile_book(book) : Comp.js_book(book);
    }
    self.postMessage({ type: "result", id, ok: true, output,
      elapsed: performance.now() - start, bytes: new TextEncoder().encode(output).length });
  } catch (e) {
    const error = e as Bend.Err;
    const output = error?.$ === "Err" ? Bend.err_show(error)
      : e instanceof RangeError ? "This program exceeds the browser evaluator's nesting limit. Try splitting long definitions into smaller functions."
      : e instanceof Error ? e.message : String(e);
    self.postMessage({ type: "result", id, ok: false, output, elapsed: performance.now() - start });
  }
};
self.postMessage({ type: "ready" });
