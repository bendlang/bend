import * as fs from "node:fs";
import * as path from "node:path";
import * as vscode from "vscode";
import {
  LanguageClient,
  TransportKind,
  type Executable,
  type LanguageClientOptions,
  type ServerOptions,
} from "vscode-languageclient/node";

const BIN = "bend2-fmt-lsp";

let client: LanguageClient | undefined;

// a .js file is run by this node; anything else is the executable itself
function runs(target: string): Executable {
  const stdio = { transport: TransportKind.stdio };
  return target.endsWith(".js")
    ? { command: process.execPath, args: [target, "--stdio"], ...stdio }
    : { command: target, args: ["--stdio"], ...stdio };
}

function onPath(): string | undefined {
  const dirs = (process.env.PATH ?? "").split(path.delimiter);
  return dirs.map((dir) => path.join(dir, BIN)).find((at) => fs.existsSync(at));
}

// the setting, then the sibling checkout (the repo's own layout), then the
// PATH; with none of them the grammar still stands on its own
function server(context: vscode.ExtensionContext): Executable | undefined {
  const setting = vscode.workspace.getConfiguration("bend")
    .get<string>("formatter.path", "").trim();
  if (setting !== "") {
    return runs(setting);
  }
  const here = fs.realpathSync(context.extensionPath); // a linked checkout
  const sibling = path.join(here, "..", "bend-fmt-lsp", "dist", "server.js");
  if (fs.existsSync(sibling)) {
    return runs(sibling);
  }
  const found = onPath();
  return found === undefined ? undefined : runs(found);
}

export async function activate(context: vscode.ExtensionContext):
  Promise<void> {
  const log = vscode.window.createOutputChannel("Bend");
  context.subscriptions.push(log);
  const found = server(context);
  if (found === undefined) {
    log.appendLine("no " + BIN + " found: highlighting only. Set"
      + " bend.formatter.path to format.");
    return;
  }
  log.appendLine("formatter: " + found.command
    + " " + (found.args ?? []).join(" "));
  const options: ServerOptions = { run: found, debug: found };
  const client_options: LanguageClientOptions = {
    documentSelector: [{ scheme: "file", language: "bend" }],
    outputChannel: log,
  };
  client = new LanguageClient(BIN, "Bend formatter", options, client_options);
  await client.start();
}

export function deactivate(): Thenable<void> | undefined {
  return client?.stop();
}
