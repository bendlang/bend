#!/usr/bin/env python3
"""Prepare the first contextual parser checkpoint; no live source mutation."""
import hashlib, json, re, shutil
from pathlib import Path

repo = Path(__file__).resolve().parents[4]
parent = repo / 'selfhost/build/phase16/local-law-source-01/project'
out = repo / 'selfhost/build/phase16/spans-context-source-01'
assert not out.exists(), out
project = out / 'project'
shutil.copytree(parent, project)

workers = set('f_tops f_top f_top_ready f_def_header f_def_header_prior f_def_prior f_def_base f_def_type f_def_body f_foreign f_law f_law_base f_law_clause f_law_type f_law_where f_law_end f_type f_type_named f_type_base f_type_params f_type_kind f_type_ctors f_type_ctor f_named_top f_law_header'.split())

def mask(text):
    chars = list(text); i = 0
    while i < len(text):
        if text[i] == '#':
            j = text.find('\n', i)
            if j < 0: j = len(text)
            chars[i:j] = ' ' * (j-i); i = j
        elif text[i] in '\"\'':
            quote=text[i]; j=i+1
            while j<len(text):
                if text[j]=='\\': j+=2; continue
                if text[j]==quote: j+=1; break
                j+=1
            chars[i:j] = ''.join('\n' if c=='\n' else ' ' for c in text[i:j]); i=j
        else: i+=1
    return ''.join(chars)

for file in (project/'src').rglob('*.bend'):
    text=file.read_text(); code=mask(text); edits=[]
    definitions=list(re.finditer(r'^def\s+(\w+)\(',code,re.M))
    for m in re.finditer(r'\b('+'|'.join(sorted(workers))+r')\(',code):
        at=m.end(); depth=1; end=at
        while depth:
            depth += (code[end]=='(')-(code[end]==')'); end+=1
        end-=1
        own=next((x for x in definitions if x.start()<=m.start()<x.end()),None)
        if own:
            typed=':' in text[at:end]
            value='+scope: FParseScope' if typed else 'scope'
        else:
            enclosing=next((x.group(1) for x in reversed(definitions) if x.start()<m.start()),'')
            value='scope' if enclosing in workers else 'f_parse_scope_empty()'
        stripped=text[at:end].rstrip(); trailing=text[at+len(stripped):end]
        add=(' ' if stripped.endswith(',') else ', ')+value
        edits.append((at+len(stripped),add))
    for m in re.finditer(r'^law\s+(\w+):\n((?:  .*\n)+)',code,re.M):
        if m.group(1) in workers:
            block=text[m.start():m.end()]; pos=m.start()+block.rfind('\n  ')+1
            edits.append((pos,'  for +scope: FParseScope\n'))
    for pos,add in sorted(edits,reverse=True): text=text[:pos]+add+text[pos:]
    if edits: file.write_text(text)

def edit(file, old, new):
    p=project/file; s=p.read_text(); assert s.count(old)==1,(file,old,s.count(old)); p.write_text(s.replace(old,new))

edit('src/front/declarations.bend',
 'f_def_header_prior(ts, rest, book, imports, unsafe || suffix, f_find(f_tx(ts), book), scope)',
 'f_def_context_header(ts, rest, book, imports, unsafe || suffix, f_decl_find(f_tx(ts), book, scope), scope)')
edit('src/front/declarations.bend',
 'f_eq(dk(f_find(name, book)), "Missing") && Bool.not(f_eq(f_alias(name, imports), name)), u => kt("ImportLaw", name, 0, 0, ks(pars))',
 'f_eq(dk(f_find(name, book)), "Missing") && (Bool.not(f_eq(f_alias(name, imports), name)) || f_def_fillable(f_decl_find(name, book, scope))), u => kt("ImportLaw", name, 0, 0, ks(pars))')
edit('src/front/declarations.bend',
 'Bool.not(f_eq(dk(f_find(f_tx(ts), book)), "Missing")), u => f_result(book, f_pn(fpe_word(ts, "duplicate declaration"',
 'f_decl_taken(f_tx(ts), book, scope), u => f_result(book, f_pn(fpe_word(ts, "duplicate declaration"')
edit('src/front/declarations.bend',
 'Bool.not(f_eq(dk(f_ctor_lookup(f_tx(ts), book)), "Missing"))',
 'f_decl_ctor_taken(f_tx(ts), book, scope)')

with (project/'src/front/declarations.bend').open('a') as f:f.write('''
# A module body sees completed dependencies; legacy parsers supply an empty scope.
type FParseScope is Data:
  FParseScope{+prior: List<&2,KDef>, +index: KDef, +ns: String, +aliases: List<&2,KTerm>, +enabled: Bool}

@unsafe
def f_parse_scope_empty() -> FParseScope:
  FParseScope{Nil{}, missing(), "", Nil{}, False{}}

@unsafe
def f_decl_prior(+name: String, +scope: FParseScope) -> KDef:
  match scope:
    case FParseScope{prior, index, ns, aliases, enabled}:
      +alias = f_alias(name, aliases)
      +own = f_choose(String, f_eq(alias, name), u => f_qual_name(name, ns), u => alias)
      +key = f_choose(String, f_declared(own, prior) || Bool.not(f_declared(name, prior)), u => own, u => name)
      +found = index_find(index, key, index_hash(key, 2166136261), 32)
      f_choose(KDef, f_eq(dk(found), "Absent"), u => f_find(name, Nil{}), u => found)

@unsafe
def f_decl_find(+name: String, +book: List<&2,KDef>, +scope: FParseScope) -> KDef:
  +local = f_find(name, book)
  f_choose(KDef, f_eq(dk(local), "Missing"), u => f_decl_prior(name, scope), u => local)

@unsafe
def f_decl_taken(+name: String, +book: List<&2,KDef>, +scope: FParseScope) -> Bool:
  match scope:
    case FParseScope{prior, index, ns, aliases, enabled}:
      Bool.not(f_eq(dk(f_find(name, book)), "Missing")) || Bool.not(f_eq(dk(index_find(index, name, index_hash(name, 2166136261), 32)), "Absent")) || Bool.not(f_eq(dk(index_find(index, f_qual_name(name, ns), index_hash(f_qual_name(name, ns), 2166136261), 32)), "Absent"))

@unsafe
def f_decl_ctor_taken(+name: String, +book: List<&2,KDef>, +scope: FParseScope) -> Bool:
  match scope:
    case FParseScope{prior, index, ns, aliases, enabled}:
      Bool.not(f_eq(dk(f_ctor_lookup(name, book)), "Missing")) || Bool.not(f_eq(dk(f_ctor_lookup(name, prior)), "Missing")) || Bool.not(f_eq(dk(f_ctor_lookup(f_qual_name(name, ns), prior)), "Missing"))

@unsafe
def f_def_context_header(+ts: List<&2,FToken>, +rest: List<&2,FToken>, +book: List<&2,KDef>, +imports: List<&2,KTerm>, +unsafe: Bool, +old: KDef, +scope: FParseScope) -> FRawResult:
  match scope:
    case FParseScope{prior, index, ns, aliases, enabled}:
      +name = f_tx(ts)
      +alias = f_alias(name, aliases)
      f_choose(FRawResult, enabled && Bool.not(f_eq(alias, name)) && f_declared(alias, prior) && f_declared(name, prior),
        u => f_result(book, fpe_point_at(kt_span("Ref", name, 0, 1, Nil{}, f_end(ts), f_end(ts)), "ambiguous imported declaration", "an unambiguous name (the alias " ++ f_import_alias_head(name) ++ " shadows " ++ name ++ ")"), imports),
        u => f_choose(FRawResult, enabled && Bool.not(f_def_fillable(old)) && Bool.not(f_eq(alias, name)),
          u => f_result(book, f_pn(fpe_word(ts, "an import alias cannot name a new declaration", "a fresh name (" ++ f_import_alias_head(name) ++ " is an import's alias)")), imports),
          u => f_def_header_prior(ts, rest, book, imports, unsafe, old, scope)))
''')

with (project/'src/load/modules.bend').open('a') as f:f.write('''
# Only the leading header is inspected before dependencies finish.
type FHeader is Data:
  FHeader{+imports: List<&2,KTerm>, +error: String, +body: String, line: U32, offset: U32}

type FCompletion is Data:
  FCompletion{+graph: FGraph, +parsed: FResult}

@unsafe
def compiler_load_abi() -> U32:
  1

@unsafe
def f_header_line(+source: String, +acc: String, +size: U32) -> FScanned:
  match source:
    case SNil{}: FScanned{String.reverse(acc), "", size}
    case SCon{c, rest}:
      f_choose(FScanned, Char.is_eq(c, '\\n'), u => FScanned{String.reverse(SCon{c, acc}), rest, U32.add(size, 1)}, u => f_header_line(rest, SCon{c, acc}, U32.add(size, dg_units(c))))

@unsafe
def f_header_space(+source: String) -> String:
  f_choose(String, Bool.not(String.is_empty(source)) && f_ascii_space(f_head(source)), u => f_header_space(f_tail(source)), u => source)

@unsafe
def f_header_prefix(+line: String) -> Bool:
  +text = f_header_space(line)
  String.is_empty(text) || Char.is_eq(f_head(text), '#') || Char.is_eq(f_head(text), '\\n') || (String.starts_with(text, "import") && (String.is_empty(f_drop_chars(text, 6)) || f_ascii_space(f_head(f_drop_chars(text, 6))) || Char.is_eq(f_head(f_drop_chars(text, 6)), '\\n')))

@unsafe
def f_header_scan(+source: String, +full: String, +start: U32, +line: U32, +offset: U32, +prefix: String) -> FHeader:
  f_header_next(f_header_line(source, "", 0), source, full, start, line, offset, prefix)

@unsafe
def f_header_next(+scanned: FScanned, +source: String, +full: String, +start: U32, +line: U32, +offset: U32, +prefix: String) -> FHeader:
  match scanned:
    case FScanned{word, rest, size}:
      f_choose(FHeader, Bool.not(String.is_empty(source)) && f_header_prefix(word),
        u => f_header_scan(rest, full, start, U32.add(line, 1), U32.add(offset, size), prefix ++ word),
        u => f_header_result(fpe_finish_indexed(start, full, f_tops(f_lex_cursor(prefix, 1, 0, 0, Nil{}, start, start), Nil{}, Nil{}, False{}, f_parse_scope_empty())), source, line, offset))

@unsafe
def f_header_result(+parsed: FResult, +body: String, +line: U32, +offset: U32) -> FHeader:
  match parsed:
    case FResult{book, error, imports}: FHeader{imports, error, body, line, offset}

@unsafe
def f_source_header(+source: FSource) -> FHeader:
  match source:
    case FSource{name, path, text}: f_header_scan(text, text, 0, 1, 0, "")
    case FParsedSource{name, path, text, parsed}: f_header_supplied(parsed)
    case FLocatedSource{inner, begin, end}: f_source_header_at(inner, begin)

@unsafe
def f_source_header_at(+source: FSource, +start: U32) -> FHeader:
  match source:
    case FSource{name, path, text}: f_header_scan(text, text, start, 1, 0, "")
    case FParsedSource{name, path, text, parsed}: f_header_supplied(parsed)
    case FLocatedSource{inner, begin, end}: FHeader{Nil{}, "nested source interval", "", 1, 0}

@unsafe
def f_header_supplied(+parsed: FResult) -> FHeader:
  match parsed:
    case FResult{book, error, imports}: FHeader{imports, "", "", 1, 0}

@unsafe
def f_header_imports(+header: FHeader) -> List<&2,KTerm>:
  match header:
    case FHeader{imports, error, body, line, offset}: imports

@unsafe
def f_source_body(+source: FSource, +header: FHeader, +scope: FParseScope, +start: U32) -> FResult:
  match source:
    case FSource{name, path, text}: f_body_header(text, header, scope, start)
    case FParsedSource{name, path, text, parsed}: parsed
    case FLocatedSource{inner, begin, end}: f_source_body(inner, header, scope, begin)

@unsafe
def f_body_header(+source: String, +header: FHeader, +scope: FParseScope, +start: U32) -> FResult:
  match header:
    case FHeader{imports, error, body, line, offset}:
      f_choose(FResult, String.is_empty(error),
        u => fpe_finish_indexed(start, source, f_tops(f_lex_cursor(body, line, 0, 0, Nil{}, f_cursor_add(start, offset), f_cursor_add(start, offset)), Nil{}, List.reverse(&2,KTerm,imports), False{}, scope)),
        u => FResult{Nil{}, error, imports})

@unsafe
def f_complete_source(+source: FSource, +ns: String, +header: FHeader, +sources: List<&2,FSource>, +graph: FGraph, +root: String) -> FCompletion:
  match graph:
    case FGraph{book, error, done}:
      f_choose(FCompletion, String.is_empty(error),
        u => f_complete_aliases(source, ns, header, graph, f_graph_aliases(f_header_imports(header), source, sources, root), book),
        u => FCompletion{graph, FResult{Nil{}, error, Nil{}}})

@unsafe
def f_complete_aliases(+source: FSource, +ns: String, +header: FHeader, +graph: FGraph, +aliases: List<&2,KTerm>, +prior: List<&2,KDef>) -> FCompletion:
  f_complete_parsed(source, ns, aliases, graph, f_source_body(source, header, FParseScope{prior, index_build(List.reverse(&2,KDef,prior)), ns, aliases, True{}}, 0))

@unsafe
def f_complete_parsed(+source: FSource, +ns: String, +aliases: List<&2,KTerm>, +graph: FGraph, +parsed: FResult) -> FCompletion:
  match parsed:
    case FResult{book, error, imports}:
      FCompletion{f_choose(FGraph, String.is_empty(error), u => f_graph_finish(source, ns, book, aliases, graph), u => f_graph_error(graph, error)), parsed}

@unsafe
def f_completion_graph(+completion: FCompletion) -> FGraph:
  match completion:
    case FCompletion{graph, parsed}: graph
''')

p=project/'src/load/seed.bend';s=p.read_text()
s=s.replace('for +r: FResult','for +r: FHeader')
s=s.replace('  for +book: List<&2, KDef>\n  for +allimports: List<&2, KTerm>\n','  for +header: FHeader\n')
s=s.replace('f_parse_source(s), seed)', 'f_source_header(s), seed)')
a=s.index('def fs_parsed(');b=s.index('\n\n# Base is larger',a)
s=s[:a]+'''def fs_parsed(s, ns, sources, g, stack, r, seed):
  fs_imports(s, ns, r, f_header_imports(r), sources, g, stack, seed)

@unsafe
def fs_imports(s, ns, header, imports, sources, g, stack, seed):
  match imports:
    case Nil{}:
      f_completion_graph(f_complete_source(s, ns, header, sources, g, fs_root(seed)))
    case Con{im, rest}:
      fs_imports(s, ns, header, rest, sources, fs_load(f_import_pathname(im, s, sources), f_import_namespace_at(im, s, sources, fs_root(seed)), sources, g, stack, seed), stack, seed)
'''+s[b:];p.write_text(s)

p=project/'tools/typed-driver.mjs';s=p.read_text()
s=s.replace("if(files.includes('src/load/modules.bend'))exports.push('f_source_parsed','f_source_located');", "if(files.includes('src/load/modules.bend')){exports.push('f_source_parsed','f_source_located');if(fs.readFileSync(path.join(project,'src/load/modules.bend'),'utf8').includes('def compiler_load_abi('))exports.push('compiler_load_abi','f_source_header','f_complete_source','f_graph_trace');}")
p.write_text(s)

changed=[]
for p in project.rglob('*'):
    if p.is_file() and (p.relative_to(project).parts[0] in ['src','tools']):
        old=parent/p.relative_to(project)
        if not old.exists() or old.read_bytes()!=p.read_bytes():changed.append({'path':str(p.relative_to(project)),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()})
(out/'manifest.json').write_text(json.dumps({'parent':str(parent),'project':str(project),'changes':changed,'checkpoint':'A; host discovery intentionally remains legacy'},indent=2)+'\n')
config=json.loads((repo/'selfhost/build/phase16/local-law-source-01/workflow.json').read_text())
config['project']=str(project);config['cpu']=2
(out/'workflow.json').write_text(json.dumps(config,indent=2)+'\n')
print(out)
