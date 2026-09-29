from pathlib import Path
import difflib, hashlib, json, shutil

root = Path(__file__).resolve().parents[4]
phase = root / 'selfhost/build/phase16'
base = phase / 'kind-origin-source-01/project'
out = phase / 'module-names-source-01'
out.mkdir()
shutil.copytree(base, out / 'project')
edits = []

def edit(file, transform):
    p = out / 'project' / file
    before = p.read_text()
    after = transform(before)
    assert after != before, file
    p.write_text(after)
    edits.append((file, before, after))

def replace(s, a, b):
    assert s.count(a) == 1, (a, s.count(a))
    return s.replace(a, b)

def pretty(s):
    s = replace(s, '  KPName{name: String, id: U32, depth: U32}',
                '  KPName{name: String, id: U32, depth: U32}\n  KPFile{+namespace: String, +aliases: List<&2,KTerm>}')
    s = replace(s, '    case Nil{}: name ++ "^" ++ U32.show(id)',
                '    case Nil{}: name ++ "^" ++ U32.show(id)\n    case Con{KPFile{ns, aliases}, tail}: kp_scope(tail, id, name)')
    s = replace(s, '    case Nil{}: id\n    case Con{KPName',
                '    case Nil{}: id\n    case Con{KPFile{ns, aliases}, tail}: kp_index(tail, id)\n    case Con{KPName')
    s = replace(s, '    case Con{h, t}: U32.add(1, kp_depth(t))',
                '    case Con{KPFile{ns, aliases}, t}: kp_depth(t)\n    case Con{KPName{n, i, depth}, t}: U32.add(1, kp_depth(t))')
    s = replace(s, '    case Con{KPName{n, i, depth}, t}: kp_eq(n, name) || kp_bound(t, name)',
                '    case Con{KPFile{ns, aliases}, t}: kp_bound(t, name)\n    case Con{KPName{n, i, depth}, t}: kp_eq(n, name) || kp_bound(t, name)')
    s = replace(s, 'def kp_removed(\n  xs: List<&2, String>,',
                'def kp_removed(\n  xs: List<&2, String>,\n  +env: List<&2, KPName>,')
    s = replace(s, '" - " ++ h ++ "{}" ++ kp_removed(t)',
                '" - " ++ kp_name(env, h) ++ "{}" ++ kp_removed(t, env)')
    s = replace(s, 'kp_par(nm(t) ++ kc(String, U32.is_eq(terms_len(ks(t)), 0)',
                'kp_par(kp_name(env, nm(t)) ++ kc(String, U32.is_eq(terms_len(ks(t)), 0)')
    s = replace(s, 'kp_removed(rm(t))', 'kp_removed(rm(t), env)')
    s = replace(s, 'case None{}: nm(t) ++ "{"', 'case None{}: kp_name(env, nm(t)) ++ "{"')
    s = replace(s, 'kp_eq(tg(t), "Mat"), u => nm(t) ++ ": "',
                'kp_eq(tg(t), "Mat"), u => kp_name(env, nm(t)) ++ ": "')
    s = replace(s, 'kp_eq(tg(t), "Ref"), u => nm(t) ++ kc(String, kp_bound(env, nm(t)),',
                'kp_eq(tg(t), "Ref"), u => kp_name(env, nm(t)) ++ kc(String, kp_bound(env, kp_name(env, nm(t))),')
    # These workers precede their callers; no loader dependency in core printing.
    marker = '@unsafe\ndef kp_show('
    workers = '''# File context is separate from lexical binders and never changes their depth.
@unsafe
def kp_alias_name(+aliases: List<&2,KTerm>, +name: String) -> String:
  match aliases:
    case Nil{}: name
    case Con{im, rest}:
      kc(String, Bool.not(List.is_empty(&2,KTerm,ks(im))) && String.starts_with(name, nm(im) ++ "."), u => nm(kid(im, 0)) ++ String.drop(name, String.length(nm(im))), u => kp_alias_name(rest, name))

@unsafe
def kp_name(+env: List<&2,KPName>, +name: String) -> String:
  match env:
    case Nil{}: name
    case Con{KPName{n, id, depth}, rest}: kp_name(rest, name)
    case Con{KPFile{ns, aliases}, rest}:
      kc(String, Bool.not(String.is_empty(ns)) && String.starts_with(name, ns ++ "."), u => String.drop(name, String.length(ns ++ ".")), u => kp_alias_name(aliases, name))

'''
    return replace(s, marker, workers + marker)

edit('src/core/pretty.bend', pretty)
edit('src/load/graph.bend', lambda s: replace(s,
    '[ref(ns)]), done}}', 'Con{ref(ns), imports}), done}}'))

def render(s):
    old = 'def dg_render_parts(book, expected, observed, has_observed, ctx, name, span, note):\n'
    start = s.index(old)
    end = s.index('\n\n@unsafe', start)
    body = s[start + len(old):end]
    body = body.replace('dg_scope(ctx, Nil{})', 'dg_scope(ctx, env)').replace('dg_context(book, ctx, Nil{},', 'dg_context(book, ctx, env,').replace('dg_location(name, span)', 'dg_location(kp_name(env, name), span)')
    worker = '''def dg_render_parts_in(
  +book: List<&2,KDef>, +expected: DExpr, +observed: DExpr,
  +has_observed: Bool, +ctx: List<&2,KTerm>, +name: String,
  +span: DSpan, +note: String, +env: List<&2,KPName>,
) -> String:
'''
    return s[:start] + worker + body + '\n\n@unsafe\n' + old + '  dg_render_parts_in(book, expected, observed, has_observed, ctx, name, span, note, Nil{})' + s[end:]

edit('src/diagnostic/render.bend', render)
edit('src/diagnostic/frontend.bend', lambda s: s + '''
# The first owned numeric range chooses the same file as diagnostic_locate.
@unsafe
def fp_module_env(+done: List<&2,KTerm>, +path: String) -> List<&2,KPName>:
  match done:
    case Nil{}: Nil{}
    case Con{head, rest}:
      kc(List<&2,KPName>, String.eq(nm(head), path), u => [KPFile{nm(kid(head, 0)), terms_tail(ks(head))}], u => fp_module_env(rest, path))

@unsafe
def fp_range_env(+sources: List<&2,FSource>, +done: List<&2,KTerm>, +begin: U32, +end: U32) -> List<&2,KPName>:
  match sources:
    case Nil{}: Nil{}
    case Con{head, rest}:
      kc(List<&2,KPName>, U32.is_gt(f_source_begin(head), 0) && U32.is_ge(begin, f_source_begin(head)) && U32.is_ge(end, begin) && U32.is_lt(end, f_source_end(head)), u => fp_module_env(done, f_source_path(head)), u => fp_range_env(rest, done, begin, end))

@unsafe
def fp_diagnostic_env(+trail: List<&2,KTerm>, +sources: List<&2,FSource>, +done: List<&2,KTerm>) -> List<&2,KPName>:
  match trail:
    case Nil{}: Nil{}
    case Con{head, rest}:
      kc(List<&2,KPName>, U32.is_gt(kb(head), 0) && fp_range_owned(kb(head), ke(head), sources), u => fp_range_env(sources, done, kb(head), ke(head)), u => fp_diagnostic_env(rest, sources, done))

@unsafe
def diagnostic_render_loaded(+result: DResult, +trace: FLoadTrace) -> String:
  match result trace:
    case DResult{error, book, DDiagnostic{expected, observed, has_observed, context, definition, span, note, trail}} FLoadTrace{loaded, done, sources}:
      kc(String, String.is_empty(error), u => "", u => kc(String, List.is_empty(&2,KTerm,trail), u => "Error: " ++ error, u => dg_render_parts_in(book, expected, observed, has_observed, List.reverse(&2,KTerm,context), definition, span, note, fp_diagnostic_env(trail, sources, done))))
''')

def host(s):
    s = replace(s, "if(files.includes('src/diagnostic/frontend.bend'))exports.push('f_load_origins_for','f_loaded_origins_for');",
                "if(files.includes('src/diagnostic/frontend.bend')){exports.push('f_load_origins_for','f_loaded_origins_for');if(fs.readFileSync(path.join(project,'src/diagnostic/frontend.bend'),'utf8').includes('def diagnostic_render_loaded('))exports.push('diagnostic_render_loaded');}")
    s = replace(s, "if(!provenance.result.error)detailed=api.diagnostic_result_locate(detailed,provenance.origins);",
                "if(!provenance.result.error){detailed=api.diagnostic_result_locate(detailed,provenance.origins);if(loadTrace&&api.diagnostic_render_loaded)return api.diagnostic_render_loaded(detailed,loadTrace);}")
    return s
edit('tools/typed-driver.mjs', host)

def identity(p):
    return {'file': str(p.resolve()), 'sha256': hashlib.sha256(p.read_bytes()).hexdigest()}

patch = out / 'module-names.patch'
patch.write_text(''.join(''.join(difflib.unified_diff(a.splitlines(True), b.splitlines(True), fromfile=f, tofile=f)) for f,a,b in edits))
(out / 'manifest.json').write_text(json.dumps({'parent': str(base), 'tool': identity(Path(__file__)), 'plan': identity(root / 'design/phase16/module-diagnostic-names.md'), 'patch': identity(patch), 'files': [{'path':f,'before':identity(base/f),'after':identity(out/'project'/f)} for f,a,b in edits]},indent=2)+'\n')
(out / 'workflow.json').write_text(json.dumps({'project':str(out/'project'),'upstream':str(root/'selfhost/.bootstrap/upstream-phase8'),'profile':'equality','cpu':'0','jobs':1},indent=2)+'\n')
shutil.copy2(__file__, out/'consumed-tool.py')
print(out)
