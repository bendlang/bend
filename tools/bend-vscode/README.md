# Bend 2 for VS Code

`bend` colors Bend 2 and formats it through `bend2-fmt-lsp`, the
formatting-only language server in `tools/bend-fmt-lsp`. It adds no
diagnostics of its own: `bend <file>.bend` is the checker.

## Install and run

Node.js 22 or newer is required.

```sh
npm install
npm run build
ln -s "$PWD" ~/.vscode/extensions/bend
```

Reload the window and a `.bend` file is colored. Formatting needs the
server, which the extension looks for in three places, in order: the
`bend.formatter.path` setting, the sibling `tools/bend-fmt-lsp/dist/
server.js` checkout, and `bend2-fmt-lsp` on the PATH. With none of them
the extension still highlights, and says so in its `Bend` output channel.

To format on save, in `settings.json`:

```json
"[bend]": { "editor.formatOnSave": true }
```

## The grammar

`syntaxes/bend.tmLanguage.json` carries the scopes of
`bend2/docs/bend.sublime-syntax`, the syntax the papers' code blocks use,
so both color Bend the same way. It parts from it in three places, all
additions: `~` is an operator (the template sigil), `.|.`, `.^.` and
`.&.` are one operator each rather than a dot and a bit symbol, and a
`0x` hash (the package imports) is a number.
