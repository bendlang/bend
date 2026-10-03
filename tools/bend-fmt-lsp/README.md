# Bend 2 formatter language server

`bend2-fmt-lsp` is a formatting-only language server for Bend 2. It supports
full-document formatting over stdio and intentionally exposes no diagnostics,
completion, hover, range-formatting, or on-type-formatting features.

## Install and run

Node.js 22 or newer is required.

```sh
npm install
npm run build
node dist/server.js --stdio
```

The server handles documents whose language ID is `bend` or `bend2`. It
preserves line breaks, blank lines, comments, literal spelling, line endings,
and the final-newline state. Formatting normalizes indentation and safe token
spacing without wrapping code. When a document cannot be tokenized safely, the
server returns no edits. Documents with inline `case` rows or unrecognized
`do` headers are also left unchanged: their continuations depend on physical
columns that this line-based formatter does not reconstruct. Supported `do`
headers have the simple shape `do M<T>:` on one line, where `M` and `T` are
names (possibly qualified); the first statement follows on a new line.
Complex types and multiline headers are left untouched. This conservative fallback
leaves the entire document unchanged, including unrelated declarations.

## Tests

`npm test` runs formatter and LSP tests. To include the real compiler layout
regressions, set absolute paths to Bun and the Bend CLI source:

```sh
BEND_FMT_TEST_BUN=/absolute/path/to/bun \
BEND_FMT_TEST_COMPILER=/absolute/path/to/bend/bend2/main.ts npm test
```

These regressions use `--check-only`; they never execute the fixture's I/O.
Without both paths, the compiler test is explicitly skipped.

## Editor setup

Neovim with `nvim-lspconfig`:

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "bend",
  callback = function()
    vim.lsp.start({
      name = "bend2-fmt-lsp",
      cmd = { "bend2-fmt-lsp", "--stdio" },
      root_dir = vim.fs.root(0, { ".git" }),
    })
  end,
})
```

Helix (`languages.toml`):

```toml
[language-server.bend2-fmt-lsp]
command = "bend2-fmt-lsp"
args = ["--stdio"]

[[language]]
name = "bend"
scope = "source.bend"
file-types = ["bend"]
language-servers = ["bend2-fmt-lsp"]
auto-format = true
```

Emacs with Eglot:

```elisp
(add-to-list 'eglot-server-programs
             '(bend-mode . ("bend2-fmt-lsp" "--stdio")))
```
