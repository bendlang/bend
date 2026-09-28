import pathlib,shutil,json,hashlib
root=pathlib.Path.cwd();old=root/'selfhost/build/phase14/laws-candidate-03/project';out=root/'selfhost/build/phase14/laws-candidate-04';out.mkdir();project=out/'project'
for name in ['src','tools','tests/frontend/phase2-rules']:shutil.copytree(old/name,project/name)
(project/'dist').mkdir()
p=project/'src/front/validate.bend';s=p.read_text();old='f_eq(dk(old), "Missing"), u => f_def_base(name, p, book, imports, unsafe)';new='f_eq(dk(old), "Missing"), u => f_choose(FRawResult, Bool.not(f_eq(f_alias(name, imports), name)) && f_eq(f_tx(f_pr(p)), "->"), u => f_result(book, f_pn(f_err(f_pr(p), "an import alias can only name a law fill without a return annotation")), imports), u => f_def_base(name, p, book, imports, unsafe))';assert s.count(old)==1;p.write_text(s.replace(old,new))
config={'project':str(project),'upstream':str(root/'selfhost/.bootstrap/upstream-phase8'),'profile':'equality','cpu':'2','jobs':1}
(out/'config.json').write_text(json.dumps(config,indent=2)+'\n')
(out/'plan.json').write_text(json.dumps({'kind':'phase14-imported-law-candidate','scope':'Reject alias-prefixed annotated definitions at parse stage; otherwise preserve candidate03.','consumedTool':str(pathlib.Path(__file__).resolve()),'sha256':hashlib.sha256(pathlib.Path(__file__).read_bytes()).hexdigest()},indent=2)+'\n')
