// ACE mode for Bend2: keywords, quantities, numbers, strings, comments,
// types and constructors. Token classes follow tools/bend-fmt-lsp KEYWORDS.
ace.define("ace/mode/bend_highlight_rules", ["require", "exports", "module", "ace/lib/oop", "ace/mode/text_highlight_rules"], function(require, exports, module) {
  const oop = require("../lib/oop");
  const TextHighlightRules = require("./text_highlight_rules").TextHighlightRules;
  const BendHighlightRules = function() {
    this.$rules = {
      start: [
        { token: "comment", regex: "#.*$" },
        { token: "string", regex: '"(?:[^"\\\\]|\\\\.)*"' },
        { token: "string", regex: "'(?:[^'\\\\]|\\\\.)*'" },
        { token: "keyword", regex: "\\b(?:import|def|type|law|match|case|do|for|exs|where|is|return)\\b" },
        { token: "constant.numeric", regex: "\\b\\d+\\.\\d+\\b|\\b\\d+n\\b|\\b\\d+\\b" },
        { token: "variable.parameter", regex: "[+~\\-&][A-Za-z_][A-Za-z0-9_]*|[+~\\-&]&[012]" },
        { token: "support.type", regex: "\\b(?:Type|Data|Kind|Quant|U32|Nat|F32|Char|String|Bool|List|Array|Maybe|Result|Unit|Empty|IO|Nat)\\b" },
        { token: "entity.name.function", regex: "\\b[A-Za-z_][A-Za-z0-9_.]*\\b(?=\\()" },
        { token: "variable", regex: "\\b[A-Z][A-Za-z0-9_]*\\b" },
        { token: "identifier", regex: "\\b[a-z_][A-Za-z0-9_]*\\b" },
        { token: "punctuation", regex: "[,:.;]" },
        { token: "keyword.operator", regex: "==|!=|->|<-|=>|&&|\\|\\||\\+\\+|<>|<&>|<=|>=|<<|>>|\\.\\|\\.|\\.\\^\\.|\\.\\&\\.|[+\\-*/%<>=!&|~^]" },
        { token: "paren.lparen", regex: "[\\[\\{\\(]" },
        { token: "paren.rparen", regex: "[\\]\\}\\)]" },
        { token: "text", regex: "\\s+" },
      ],
    };
    this.normalizeRules();
  };
  oop.inherits(BendHighlightRules, TextHighlightRules);
  exports.BendHighlightRules = BendHighlightRules;
});
ace.define("ace/mode/bend", ["require", "exports", "module", "ace/lib/oop", "ace/mode/text", "ace/mode/bend_highlight_rules"], function(require, exports, module) {
  const oop = require("../lib/oop");
  const TextMode = require("./text").Mode;
  const BendHighlightRules = require("./bend_highlight_rules").BendHighlightRules;
  const Mode = function() {
    this.HighlightRules = BendHighlightRules;
  };
  oop.inherits(Mode, TextMode);
  // Python-shaped blocks: a trailing colon deepens the next line.
  Mode.prototype.getNextLineIndent = function(state, line) {
    const indent = line.match(/^ */)[0];
    return indent + (line.trimEnd().endsWith(":") ? "  " : "");
  };
  exports.Mode = Mode;
});
