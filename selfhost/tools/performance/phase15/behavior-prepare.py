import pathlib, shutil, json, hashlib, difflib
root=pathlib.Path.cwd(); base=root/'selfhost'; out=base/'build/phase15/behavior-source-01'; out.mkdir(); project=out/'project'
for name in ['src','tools','tests/frontend/phase2-rules']: shutil.copytree(base/name,project/name)
(project/'dist').mkdir()
changes=[]
def edit(name, transform):
 p=project/name; before=p.read_text(); after=transform(before); assert before!=after,name; p.write_text(after)
 changes.append({'file':name,'beforeSha256':hashlib.sha256(before.encode()).hexdigest(),'afterSha256':hashlib.sha256(after.encode()).hexdigest(),'physicalLineDelta':len(after.splitlines())-len(before.splitlines()),'byteDelta':len(after.encode())-len(before.encode())})
 (out/(name.replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(before.splitlines(True),after.splitlines(True),fromfile=name,tofile=name)))
def replace(s,old,new):
 assert s.count(old)==1,(old,s.count(old));return s.replace(old,new)
edit('src/front/sugar.bend',lambda s:replace(s,'  f_statement(FParsed{kt("Ref", f_tx(ts), f_atid(ts), 0, Nil{}), f_tl(ts)})','  f_choose(FParsed, f_valid_name(f_tx(ts)), u => f_statement(FParsed{kt("Ref", f_tx(ts), f_atid(ts), 0, Nil{}), f_tl(ts)}), u => fpe_error(ts, "expected a name", "a name"))'))
edit('src/front/declarations.bend',lambda s:replace(s,'  f_import_path(ts, "", book, imports)','  f_import_path(ts, ts, "", book, imports)'))
def imports(s):
 s=replace(s,'  for +ts: List<&2, FToken>\n','  for +ts: List<&2, FToken>\n  for +start: List<&2, FToken>\n')
 s=replace(s,'def f_import_path(ts, path, book, imports):','def f_import_path(ts, start, path, book, imports):')
 s=s.replace('f_import_alias(ts, path, book, imports)','f_import_alias(ts, start, path, book, imports)').replace('kt("Import", path, 0, 0, Nil{})','kt("Import", path, f_line(start), f_col(start), Nil{})').replace('f_import_path(f_tl(ts), path ++ f_tx(ts), book, imports)','f_import_path(f_tl(ts), start, path ++ f_tx(ts), book, imports)')
 return s+'''
# Local imports use the pinned plain-segment grammar before path resolution.
# Hub/package resolution is unchanged and remains outside this host's scope.
@unsafe
def f_import_valid(+path: String) -> Bool:
  f_choose(Bool, Bool.not(String.starts_with(path, "./") || String.starts_with(path, "../") || String.starts_with(path, "/")) && (String.starts_with(path, "0x") || String.contains(path, "@")), u => True{}, u => f_import_local(f_strip_bend(f_choose(String, String.starts_with(path, "./"), u => f_drop_chars(path, 2), u => path))))

@unsafe
def f_import_local(+path: String) -> Bool:
  f_choose(Bool, String.starts_with(path, "/"), u => f_import_segments(f_tail(path), True{}), u => f_import_parents(path))

@unsafe
def f_import_parents(+path: String) -> Bool:
  f_choose(Bool, String.starts_with(path, "../"), u => f_import_parents(f_drop_chars(path, 3)), u => f_import_segments(path, True{}))

@unsafe
def f_import_segments(+path: String, +head: Bool) -> Bool:
  match path:
    case SNil{}: Bool.not(head)
    case SCon{c, rest}:
      f_choose(Bool, Char.is_eq(c, '/'), u => Bool.not(head) && f_import_segments(rest, True{}), u => (f_ascii_alpha(c) || Char.is_eq(c, '_') || (Bool.not(head) && (Char.is_digit(c) || Char.is_eq(c, '-')))) && f_import_segments(rest, False{}))

# Import nodes carry the original path token's line and code-point column.
# Convert this location to UTF-16 only when presenting an IO failure.
@unsafe
def f_import_offset(+source: String, +line: U32, +column: U32, +offset: U32) -> U32:
  match source:
    case SNil{}: offset
    case SCon{c, rest}:
      f_choose(U32, U32.is_gt(line, 1), u => f_import_offset(rest, f_choose(U32, Char.is_eq(c, '\\n'), u => U32.sub(line, 1), u => line), column, U32.add(offset, dg_units(c))), u => f_choose(U32, U32.is_eq(column, 0), u => offset, u => f_import_offset(rest, line, U32.sub(column, 1), U32.add(offset, dg_units(c)))))

@unsafe
def f_import_missing(+source: String, +im: KTerm, +path: String) -> String:
  +offset = f_import_offset(source, ix(im), qt(im), 0)
  "Error:\\n- message  : no such file: " ++ path ++ "\\nLocation:" ++ dg_snippet(DSpan{source, offset, offset})
'''
edit('src/load/imports.bend',imports)
def validate(s):
 s=replace(s,'def f_import_alias(\n  +ts: List<&2, FToken>,','def f_import_alias(\n  +ts: List<&2, FToken>,\n  +start: List<&2, FToken>,')
 old='u => f_tops(f_tl(f_tl(ts)), book, Con{kt("Import", path, 0, 0, [kt("Alias", f_tx(f_tl(ts)), 0, 0, Nil{})]), imports}, False{}))'
 new='u => f_choose(FRawResult, f_import_valid(path), u => f_tops(f_tl(f_tl(ts)), book, Con{kt("Import", path, f_line(start), f_col(start), [kt("Alias", f_tx(f_tl(ts)), 0, 0, Nil{})]), imports}, False{}), u => f_result(book, f_pn(fpe_error(start, "invalid import path", "an import path of plain names (letters, digits, _ and -; the hub\\\'s files import the hub\\\'s)")), imports)))'
 return replace(s,old,new)
edit('src/front/validate.bend',validate)
def host(s):
 s=replace(s,"  if(files.includes('src/load/modules.bend'))exports.push('f_source_parsed');", "  if(files.includes('src/load/modules.bend'))exports.push('f_source_parsed');\n  if(fs.readFileSync(path.join(project,'src/load/imports.bend'),'utf8').includes('def f_import_missing('))exports.push('f_import_missing');")
 s=replace(s,"    if(parsed.error) throw Object.assign(Error(parsed.error),{phase:'parse',sourceFile:absolute});\n",'')
 s=replace(s,"      visit(graphMode&&imported!=='Base'?importedFile:imported,importedFile);", "      try { visit(graphMode&&imported!=='Base'?importedFile:imported,importedFile); }\n      catch(error) {\n        if(error.code==='ENOENT'&&!error.phase&&api.f_import_missing)\n          throw Object.assign(Error(api.f_import_missing(source,item,importedFile)),{phase:'parse',sourceFile:absolute});\n        throw error;\n      }")
 return replace(s,"    }\n  };\n  const main=graphMode?", "    }\n    // Upstream loads earlier imports before it parses this module's body.\n    if(parsed.error) throw Object.assign(Error(parsed.error),{phase:'parse',sourceFile:absolute});\n  };\n  const main=graphMode?")
edit('tools/typed-driver.mjs',host)
(out/'config.json').write_text(json.dumps({'project':str(project),'upstream':str(base/'.bootstrap/upstream-phase8'),'profile':'equality','cpu':'2','jobs':1},indent=2)+'\n')
(out/'manifest.json').write_text(json.dumps({'kind':'phase15-behavior-source','changes':changes,'tool':str(pathlib.Path(__file__).resolve()),'toolSha256':hashlib.sha256(pathlib.Path(__file__).read_bytes()).hexdigest()},indent=2)+'\n')
print(out)
