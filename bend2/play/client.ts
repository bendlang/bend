export {};

const get = <T extends HTMLElement>(id: string) => document.getElementById(id) as T;
const source = get<HTMLTextAreaElement>("source");
const output = get<HTMLTextAreaElement>("output");
const results = get<HTMLTextAreaElement>("results");
const stdinBox = get<HTMLTextAreaElement>("stdin");
const example = get<HTMLSelectElement>("example");
type Action = "interpret" | "compile-run" | "compile-js" | "compile-c";
const actions: Action[] = ["interpret", "compile-run", "compile-js", "compile-c"];
const cancel = get<HTMLButtonElement>("cancel");
const copy = get<HTMLButtonElement>("copy");
const download = get<HTMLButtonElement>("download");
const numbers = get<HTMLPreElement>("line-numbers");
const examples: Record<string, string> = {
  hello: `import Base

# A small program, ready to compile.
def greet(name: String) -> String:
  String.append("Hello, ", name)

def main() -> IO(Unit):
  IO.print(greet("Bend"))
`,
  numbers: `import Base

# A + parameter can be used more than once.
def square(+x: U32) -> U32:
  U32.mul(x, x)

def main() -> U32:
  square(12)
`,
  lists: `import Base

# Types say exactly what goes in and comes out.
def main() -> U32:
  List.foldl(~&2, ~U32, ~U32, ~U32.add, [1, 2, 3, 4, 5], 0)
`,
  error: `import Base

# This function promises a number.
# Change the string to 42 and compile again.
def main() -> U32:
  "not a number"
`,
  calc: `import Base

# A calculator: each IO.read_line takes one line from Stdin.
# Try 40 and 2, then Compile to JS and run.
def calc.usage() -> IO(U32):
  do IO<U32>:
    u : Unit <- IO.print("usage: enter two numbers, one per line")
    return 0

def calc.bad() -> IO(U32):
  do IO<U32>:
    u : Unit <- IO.print("not a number")
    return 0

def calc.done(n: U32, m: Maybe<&2, U32>) -> IO(U32):
  match m:
    case None{}:
      calc.bad()
    case Some{k}:
      do IO<U32>:
        u : Unit <- IO.print(U32.show(U32.add(n, k)))
        return 0

def calc.with_n(n: U32, y: String) -> IO(U32):
  calc.done(n, U32.read(y))

def calc.with_m(m: Maybe<&2, U32>, y: String) -> IO(U32):
  match m:
    case None{}:
      calc.bad()
    case Some{n}:
      calc.with_n(n, y)

def calc.with_xy(x: String, y: String) -> IO(U32):
  calc.with_m(U32.read(x), y)

def calc.with_x(x: String, b: Maybe<&1, String>) -> IO(U32):
  match b:
    case None{}:
      calc.usage()
    case Some{y}:
      calc.with_xy(x, y)

def calc.go(a: Maybe<&1, String>, b: Maybe<&1, String>) -> IO(U32):
  match a:
    case None{}:
      calc.usage()
    case Some{x}:
      calc.with_x(x, b)

def main() -> IO(U32):
  do IO<U32>:
    a : Maybe<&1, String> <- IO.read_line()
    b : Maybe<&1, String> <- IO.read_line()
    n : U32 <- calc.go(a, b)
    return n
`,
};
const exampleStdin: Record<string, string> = {
  calc: "40\n2\n",
};
const storageKey = "bend.playground.v1";
let worker: Worker;
let runner: Worker | undefined;
let ready = false;
let busy = false;
let phase = "Compiling…";
let tab: "results" | "compiled" = "results";
let generation = 0;
let request = 0;
let timer: ReturnType<typeof setTimeout>;
let compiledSource = "";
let compiledTarget = "";
let activeSource = "";
let activeTarget = "";
let activeAction: Action = "compile-run";

function status(text: string, state = ""): void {
  get("status-text").textContent = text;
  get("status").className = state;
}
function visibleOutput(): HTMLTextAreaElement { return tab === "results" ? results : output; }
function controls(): void {
  for (const action of actions) get<HTMLButtonElement>(action).disabled = !ready || busy;
  cancel.hidden = !busy;
  source.setAttribute("aria-busy", String(busy));
  copy.disabled = download.disabled = !visibleOutput().value;
}
function selectTab(next: typeof tab, focus = false): void {
  tab = next;
  for (const name of ["results", "compiled"] as const) {
    const button = get("tab-" + name);
    button.setAttribute("aria-selected", String(tab === name));
    button.tabIndex = tab === name ? 0 : -1;
    get("panel-" + name).hidden = tab !== name;
  }
  if (focus) get("tab-" + tab).focus();
  controls();
}
for (const name of ["results", "compiled"] as const) {
  get("tab-" + name).addEventListener("click", () => selectTab(name));
  get("tab-" + name).addEventListener("keydown", event => {
    if (["ArrowLeft", "ArrowRight", "Home", "End"].includes(event.key)) {
      event.preventDefault();
      selectTab(event.key === "Home" ? "results" : event.key === "End" ? "compiled" : tab === "results" ? "compiled" : "results", true);
    }
  });
}
function persist(): void {
  try { localStorage.setItem(storageKey, JSON.stringify({ source: source.value, example: example.value, stdin: stdinBox.value, mode: stdinMode() })); } catch {}
}
function stdinMode(): string {
  return document.querySelector<HTMLInputElement>('input[name="stdin-mode"]:checked')?.value ?? "prefill";
}
function position(): void {
  const before = source.value.slice(0, source.selectionStart);
  get("cursor").textContent = `Ln ${before.split("\n").length}, Col ${before.length - before.lastIndexOf("\n")}`;
}
function stale(): boolean { return source.value !== compiledSource; }
function elapsed(ms: number): string { return ms < 1000 ? Math.round(ms) + " ms" : (ms / 1000).toFixed(2) + " s"; }
function edit(): void {
  const count = source.value.split("\n").length;
  numbers.textContent = Array.from({ length: count }, (_, i) => String(i + 1)).join("\n");
  numbers.scrollTop = source.scrollTop;
  position();
  persist();
  if (!busy && ready) status("Ready");
  if ((output.value || results.value) && stale()) get("output-state").textContent = "Source changed · run or compile to update";
}
function finish(message: string, failed = false): void {
  clearTimeout(timer);
  runner?.terminate();
  runner = undefined;
  get("inputbar").hidden = true;
  busy = false;
  results.className = failed ? "error" : "";
  get("output-state").textContent = stale() ? "Source changed · run or compile to update" : message;
  status(stale() ? "Source changed · run or compile again for the latest version" : message, failed ? "error" : "success");
  if (failed) selectTab("results");
  controls();
}
function stop(message: string): void {
  results.value += (results.value && !results.value.endsWith("\n") ? "\n" : "") + message + "\n";
  get("output-state").textContent = message;
  selectTab("results");
  restart(message);
}
function execute(javascript: string, compileTime: number): void {
  phase = "Running…";
  results.placeholder = "Running JavaScript…";
  controls();
  status("Compiled in " + elapsed(compileTime) + " · running JavaScript…", "busy");
  get("output-state").textContent = "Running JavaScript…";
  const current = request;
  runner = new Worker("/runner.js", { type: "module" });
  runner.onmessage = ({ data }) => {
    if (current !== request || !busy) return;
    if (data.type === "output") {
      results.value += data.text;
      results.scrollTop = results.scrollHeight;
      controls();
    } else if (data.type === "input-request") {
      const bar = get("inputbar");
      const line = get<HTMLInputElement>("inputline");
      if (bar.hidden) {
        bar.hidden = false;
        get("output-state").textContent = "Waiting for input…";
        status("Waiting for input…", "busy");
      }
      line.focus();
    } else if (data.type === "done") {
      if (!results.value) results.value = "Program finished without output.\n";
      finish(`Exit ${data.code} · ran in ${elapsed(data.elapsed)} · compiled in ${elapsed(compileTime)}`, data.code !== 0);
    }
  };
  runner.onerror = event => {
    event.preventDefault();
    results.value += (event.message || "The execution worker stopped.") + "\n";
    finish("Execution failed", true);
  };
  runner.postMessage({ javascript, stdin: stdinMode() === "ask" ? "" : stdinBox.value });
  timer = setTimeout(() => stop("Execution stopped after 30 seconds."), 30_000);
}
function restart(message?: string, runWhenReady?: Action): void {
  worker?.terminate();
  runner?.terminate();
  runner = undefined;
  get("inputbar").hidden = true;
  clearTimeout(timer);
  generation += 1;
  request += 1;
  ready = busy = false;
  controls();
  status(message ?? "Loading the compiler…");
  const current = generation;
  worker = new Worker("/worker.js", { type: "module" });
  worker.onmessage = ({ data }) => {
    if (current !== generation) return;
    if (data.type === "ready") {
      ready = true;
      controls();
      status(message ?? "Ready");
      if (runWhenReady) run(runWhenReady);
      return;
    }
    if (data.type !== "result" || data.id !== request || !busy) return;
    clearTimeout(timer);
    compiledSource = activeSource;
    compiledTarget = activeTarget;
    if (!data.ok) {
      results.value = data.output;
      finish(activeAction === "interpret" ? "Couldn’t interpret this program" : "Couldn’t compile this program", true);
      return;
    }
    if (activeAction === "interpret") {
      results.value = data.output;
      finish("Interpreted in " + elapsed(data.elapsed));
      return;
    }
    output.value = data.output;
    output.scrollTop = output.scrollLeft = 0;
    get("output-size").textContent = compiledTarget.toUpperCase() + " · " + (data.bytes / 1024).toFixed(1) + " KB";
    if (activeAction === "compile-run") {
      execute(data.output, data.elapsed);
    } else {
      results.value = "Compiled to " + (compiledTarget === "c" ? "C" : "JavaScript") + " successfully. The program was not executed.\n";
      selectTab("compiled");
      finish("Compiled in " + elapsed(data.elapsed));
    }
  };
  worker.onerror = event => {
    event.preventDefault();
    worker.terminate();
    ready = true;
    worker.onmessage = null;
    results.value = (event.message || "The compiler stopped.") + "\nChoose an action to retry.";
    finish("Compiler stopped", true);
  };
}
function run(action: Action = "compile-run"): void {
  if (busy || !ready) return;
  if (!worker.onmessage) { restart(undefined, action); return; }
  activeSource = source.value;
  activeAction = action;
  activeTarget = action === "compile-c" ? "c" : action === "interpret" ? "" : "js";
  request += 1;
  busy = true;
  phase = action === "interpret" ? "Interpreting…" : "Compiling…";
  output.value = results.value = "";
  results.className = "";
  results.placeholder = phase;
  get("output-size").textContent = "—";
  get("output-state").textContent = phase;
  selectTab("results");
  status(phase, "busy");
  worker.postMessage({ id: request, source: activeSource, action });
  timer = setTimeout(() => stop(action === "interpret" ? "Interpretation stopped after 30 seconds." : "Compilation stopped after 30 seconds. Try a smaller program."), 30_000);
}

source.value = examples.hello;
try {
  const saved = JSON.parse(localStorage.getItem(storageKey) ?? "null");
  if (saved && typeof saved.source === "string") source.value = saved.source;
  if (saved?.example in examples) example.value = saved.example;
  if (saved && typeof saved.stdin === "string") stdinBox.value = saved.stdin;
  const mode = saved && (saved.mode === "ask" || saved.mode === "prefill") ? saved.mode : null;
  if (mode) {
    const radio = document.querySelector<HTMLInputElement>(`input[name="stdin-mode"][value="${mode}"]`);
    if (radio) radio.checked = true;
  }
  if (stdinMode() === "ask") {
    stdinBox.placeholder = "Ask-me mode: the box is ignored, the worker waits and asks you per line.";
  }
} catch {}
source.setSelectionRange(0, 0);
const mac = /Mac|iPhone|iPad/.test(navigator.platform);
get("shortcut").textContent = mac ? "⌘ Enter" : "Ctrl Enter";
get("compile-run").title = (mac ? "⌘ Enter" : "Ctrl Enter") + " to compile to JavaScript and run";
source.addEventListener("input", edit);
stdinBox.addEventListener("input", persist);
for (const radio of document.querySelectorAll<HTMLInputElement>('input[name="stdin-mode"]')) {
  radio.addEventListener("change", () => {
    stdinBox.placeholder = stdinMode() === "ask"
      ? "Ask-me mode: the box is ignored, the worker waits and asks you per line."
      : "Prefilled lines for IO.read_line, one per line. When they run out the program asks you below.";
    persist();
  });
}
source.addEventListener("scroll", () => { numbers.scrollTop = source.scrollTop; });
for (const event of ["click", "keyup", "select"]) source.addEventListener(event, position);
source.addEventListener("keydown", (event) => {
  if (event.key === "Tab" && !event.shiftKey) {
    event.preventDefault();
    source.setRangeText("  ", source.selectionStart, source.selectionEnd, "end");
    edit();
  } else if (event.key === "Enter" && !event.ctrlKey && !event.metaKey) {
    event.preventDefault();
    const line = source.value.slice(0, source.selectionStart).split("\n").pop()!;
    const indent = line.match(/^ */)![0] + (line.trimEnd().endsWith(":") ? "  " : "");
    source.setRangeText("\n" + indent, source.selectionStart, source.selectionEnd, "end");
    edit();
  }
});
document.addEventListener("keydown", (event) => {
  if ((event.ctrlKey || event.metaKey) && event.key === "Enter") {
    event.preventDefault();
    run();
  }
});
function sendInput(): void {
  if (!busy || !runner) return;
  runner.postMessage({ text: get<HTMLInputElement>("inputline").value });
  get<HTMLInputElement>("inputline").value = "";
  get("output-state").textContent = "Running JavaScript…";
  status("Running JavaScript…", "busy");
  get<HTMLInputElement>("inputline").focus();
}
function sendEOF(): void {
  if (!busy || !runner) return;
  runner.postMessage({ eof: true });
  get("inputbar").hidden = true;
}
for (const action of actions) get(action).addEventListener("click", () => run(action));
get("send").addEventListener("click", sendInput);
get("eof").addEventListener("click", sendEOF);
get<HTMLInputElement>("inputline").addEventListener("keydown", (event) => {
  if (event.key === "Enter") {
    event.preventDefault();
    sendInput();
  }
});
cancel.addEventListener("click", () => stop(phase === "Running…" ? "Execution cancelled." : phase === "Interpreting…" ? "Interpretation cancelled." : "Compilation cancelled."));
function reset(): void {
  if (busy) restart();
  source.value = examples[example.value];
  if (example.value in exampleStdin) stdinBox.value = exampleStdin[example.value];
  source.scrollTop = source.scrollLeft = 0;
  source.setSelectionRange(0, 0);
  edit();
}
example.addEventListener("change", reset);
get("reset").addEventListener("click", reset);
copy.addEventListener("click", async () => {
  try {
    await navigator.clipboard.writeText(visibleOutput().value);
    copy.textContent = "Copied!";
    setTimeout(() => { copy.textContent = "Copy"; }, 1600);
  } catch {
    visibleOutput().focus();
    visibleOutput().select();
    status("Select and copy the output with your keyboard.");
  }
});
download.addEventListener("click", () => {
  const url = URL.createObjectURL(new Blob([visibleOutput().value], { type: "text/plain;charset=utf-8" }));
  const link = document.createElement("a");
  link.href = url;
  link.download = tab === "compiled" ? "main." + compiledTarget : "results.txt";
  link.click();
  setTimeout(() => URL.revokeObjectURL(url), 1000);
});
edit();
restart();
