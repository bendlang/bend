#!/usr/bin/env python3
from pathlib import Path
import json,hashlib,shutil,difflib
ROOT=Path(__file__).resolve().parents[4];BASE=ROOT/'selfhost/build/phase16/wave7-source-01/project';OUT=ROOT/'selfhost/build/phase16/program-completion-source-01';OUT.mkdir();shutil.copytree(BASE,OUT/'project');P=OUT/'project'
p=P/'src/diagnostic/produce.bend';s=p.read_text()
def change(a,b):
 global s
 assert s.count(a)==1,(a,s.count(a));s=s.replace(a,b)
workers=['dg_seed_books','dg_prefix_seed','dg_suffix_events','dg_suffix_guard','dg_suffix_check','dg_prefix_step']
for name in workers:
 at=s.index('law '+name+':');end=s.index('\n  DResult',at);s=s[:end]+'\n  for +complete: Bool'+s[end:]
 at=s.index('def '+name+'(');end=s.index('):',at);s=s[:end]+', complete'+s[end:]
change('dg_seed_books(book, Nil{}, origins, book_cached(Nil{}, norm_max_book(book)))','dg_seed_books(book, Nil{}, origins, book_cached(Nil{}, norm_max_book(book)), True{})')
change('dg_seed_books(book, validated, origins, book_cached(Nil{}, norm_max_book(book)))','dg_seed_books(book, validated, origins, book_cached(Nil{}, norm_max_book(book)), True{})')
change('dg_prefix_seed(book, validated, check_declarations(book, seed), seed, book, origins)','dg_prefix_seed(book, validated, check_declarations(book, seed), seed, book, origins, complete)')
change('dg_suffix_events(todo, done, seen, original, origins)','dg_suffix_events(todo, done, seen, original, origins, complete)')
change('dg_prefix_step(todo, head, tail, done, seen, original, origins)','dg_prefix_step(todo, head, tail, done, seen, original, origins, complete)')
change('dg_suffix_finish(done, seen, original, origins, check_open(done))','dg_suffix_finish(done, seen, original, origins, kc(String, complete, u => check_open(done), u => ""))')
change('dg_suffix_guard(rest, done, d, seen, original, origins, event_error(seen, d, lookup(seen, dn(d))))','dg_suffix_guard(rest, done, d, seen, original, origins, event_error(seen, d, lookup(seen, dn(d))), complete)')
change('dg_suffix_check(rest, done, d, seen, original, origins, check_definition_result(done, signature_mode(d, rest)))','dg_suffix_check(rest, done, d, seen, original, origins, check_definition_result(done, signature_mode(d, rest)), complete)')
change('dg_suffix_events(rest, check_event_install(done, d, rest), book_put(seen, d), original, origins)','dg_suffix_events(rest, check_event_install(done, d, rest), book_put(seen, d), original, origins, complete)')
change('case Nil{}: check_book_diagnostic(original, origins)','case Nil{}: dg_seed_books(original, Nil{}, origins, book_cached(Nil{}, norm_max_book(original)), complete)')
change('dg_prefix_seed(rest, tail, check_event_install(done, head, rest), book_put(seen, head), original, origins)','dg_prefix_seed(rest, tail, check_event_install(done, head, rest), book_put(seen, head), original, origins, complete)')
change('def compiler_check_result_abi() -> U32:\n  1','def compiler_check_result_abi() -> U32:\n  2');p.write_text(s)
p=P/'src/driver/api.bend';s=p.read_text();s+='''
# Program completion follows ordinary and live-instance validation. Legacy
# diagnostic APIs retain their own open-law completion contract.
@unsafe
def check_program_diagnostic(+book: List<&2,KDef>, +validated: List<&2,KDef>, +origins: List<&2,DOrigin>) -> DResult:
  driver_program_checked(book, origins, dg_seed_books(book, kc(List<&2,KDef>, exact_prefix(book, validated), u => validated, u => Nil{}), origins, book_cached(Nil{}, norm_max_book(book)), False{}))

@unsafe
def driver_program_checked(+original: List<&2,KDef>, +origins: List<&2,DOrigin>, +checked: DResult) -> DResult:
  match checked:
    case DResult{error, book, diagnostic}:
      kc(DResult, String.eq(error, ""), u => driver_program_specialized(original, origins, specialize_book(book)), u => checked)

@unsafe
def driver_program_specialized(+original: List<&2,KDef>, +origins: List<&2,DOrigin>, +specialized: KSpecialized) -> DResult:
  kc(DResult, String.eq(specialized_error(specialized), ""),
    u => driver_program_complete(specialized_book(specialized), origins, check_open_message(driver_todos(original))),
    u => diagnostic_result_locate(specialized_diagnostic(specialized), origins))

@unsafe
def driver_program_complete(+book: List<&2,KDef>, +origins: List<&2,DOrigin>, +error: String) -> DResult:
  dg_finish(error, book, dg_no_report("", error), origins)
''';p.write_text(s)
p=P/'tools/typed-driver.mjs';s=p.read_text()
change("  if(files.includes('src/diagnostic/produce.bend'))exports.push('compiler_check_result_abi','check_book_diagnostic','check_book_diagnostic_from_exact_prefix','diagnostic_render','diagnostic_result_locate');","  if(files.includes('src/diagnostic/produce.bend'))exports.push('compiler_check_result_abi','check_book_diagnostic','check_book_diagnostic_from_exact_prefix','diagnostic_render','diagnostic_result_locate');\n  if(files.includes('src/driver/api.bend')&&fs.readFileSync(path.join(project,'src/driver/api.bend'),'utf8').includes('def check_program_diagnostic('))exports.push('check_program_diagnostic');")
change('''    const checkedResult=api.compiler_check_result_abi?.()===1?
      (cached?api.check_book_diagnostic_from_exact_prefix(loaded.book,cached.book,list([])):api.check_book_diagnostic(loaded.book,list([]))):null;''','''    const checkAbi=typeof api.compiler_check_result_abi==='function'?api.compiler_check_result_abi():0;
    if(![0,1,2].includes(checkAbi))throw Error(`Unsupported compiler checker-result ABI: ${checkAbi}`);
    if(checkAbi===2&&typeof api.check_program_diagnostic!=='function')throw Error('Compiler checker-result ABI 2 requires check_program_diagnostic');
    const checkedResult=checkAbi===2?api.check_program_diagnostic(loaded.book,cached?cached.book:list([]),list([])):checkAbi===1?
      (cached?api.check_book_diagnostic_from_exact_prefix(loaded.book,cached.book,list([])):api.check_book_diagnostic(loaded.book,list([]))):null;''')
change('if(api.check_book_diagnostic&&api.diagnostic_render) {','if((checkedResult||api.check_book_diagnostic)&&api.diagnostic_render) {')
change('''    const todos=api.driver_todos(loaded.book);
    if(todos) return {status:'error',phase,diagnostic:`Error: ${todos} TODO${todos===1?'':'s'} found.\\nThe code is incomplete, and not a valid proof yet.`,exitCode:1,checked:true};
    let book=loaded.book;
    if(api.specialize_book) {
      trace('specialize book');
      const specialized=api.specialize_book(book),error=api.specialized_error(specialized);
      if(error) return {status:'error',phase,diagnostic:renderDiagnostic(api,api.specialized_diagnostic?.(specialized),error,loadTrace,graph),exitCode:1,checked:true};
      book=api.specialized_book(specialized);
    }''','''    let book=checkAbi===2?checkedResult.book:loaded.book;
    if(checkAbi!==2) {
      const todos=api.driver_todos(loaded.book);
      if(todos) return {status:'error',phase,diagnostic:`Error: ${todos} TODO${todos===1?'':'s'} found.\\nThe code is incomplete, and not a valid proof yet.`,exitCode:1,checked:true};
      if(api.specialize_book) {
        trace('specialize book');
        const specialized=api.specialize_book(book),error=api.specialized_error(specialized);
        if(error) return {status:'error',phase,diagnostic:renderDiagnostic(api,api.specialized_diagnostic?.(specialized),error,loadTrace,graph),exitCode:1,checked:true};
        book=api.specialized_book(specialized);
      }
    }''');p.write_text(s)
changes=[]
for rel in ['src/diagnostic/produce.bend','src/driver/api.bend','tools/typed-driver.mjs']:
 a=BASE/rel;b=P/rel;x=a.read_text();y=b.read_text();(OUT/(rel.replace('/','_')+'.patch')).write_text(''.join(difflib.unified_diff(x.splitlines(True),y.splitlines(True),fromfile='parent/'+rel,tofile='candidate/'+rel)));changes.append({'file':rel,'beforeSha256':hashlib.sha256(a.read_bytes()).hexdigest(),'afterSha256':hashlib.sha256(b.read_bytes()).hexdigest(),'lineDelta':len(y.splitlines())-len(x.splitlines()),'byteDelta':len(b.read_bytes())-len(a.read_bytes())})
(OUT/'manifest.json').write_text(json.dumps({'complete':True,'parent':str(BASE),'plan':'experiments/phase16/P16-program-completion.md','changes':changes},indent=2)+'\n');(OUT/'workflow.json').write_text(json.dumps({'project':str(P),'upstream':str(ROOT/'selfhost/.bootstrap/upstream-phase8'),'cpu':'3','jobs':1,'profile':'equality','timeoutMs':30000},indent=2)+'\n');shutil.copy2(__file__,OUT/Path(__file__).name);print(OUT)
