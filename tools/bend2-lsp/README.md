# Bend 2 language server

`bend2-lsp` provides formatting, live compiler diagnostics, and Markdown hover
information for Bend 2 over LSP stdio. Node.js 22 or newer is required.

```sh
npm install
npm run build
bend2-lsp --stdio
```

The server accepts the `bend` and `bend2` language IDs. It uses full-document
sync, publishes diagnostics on open and 250 ms after edits, and rechecks open
documents that import a changed buffer. Open buffers override files on disk.
Compiler analysis is limited to `file:` documents; untitled documents still
receive formatting, lexical diagnostics, and syntax hover.

Analysis uses the bundled Bend compiler and Base library in a worker thread.
Relative imports resolve from the document, then from open overlays. Hash
package imports use `BEND_LIB`; missing packages may be downloaded from
`BEND_HUB`, checked by the compiler, and cached in the normal package layout.
Downloads time out after 10 seconds.

The formatter preserves line breaks, blank lines, comments, literal spelling,
line endings, and final-newline state. It normalizes indentation and safe token
spacing without wrapping code.

## Editor setup

Neovim with `nvim-lspconfig`:

```lua
vim.api.nvim_create_autocmd("FileType", {
  pattern = "bend",
  callback = function()
    vim.lsp.start({
      name = "bend2-lsp",
      cmd = { "bend2-lsp", "--stdio" },
      root_dir = vim.fs.root(0, { ".git" }),
    })
  end,
})
```

Helix (`languages.toml`):

```toml
[language-server.bend2-lsp]
command = "bend2-lsp"
args = ["--stdio"]

[[language]]
name = "bend"
scope = "source.bend"
file-types = ["bend"]
language-servers = ["bend2-lsp"]
auto-format = true
```

Emacs with Eglot:

```elisp
(add-to-list 'eglot-server-programs
             '(bend-mode . ("bend2-lsp" "--stdio")))
```

Local-variable type hover is intentionally out of scope because it would
require instrumentation in the trusted checker. Unknown names and inferred
locals therefore return no hover.
