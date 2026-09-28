import pathlib,shutil,json,hashlib
root=pathlib.Path.cwd();old=root/'selfhost/build/phase14/laws-candidate-02/project';out=root/'selfhost/build/phase14/laws-candidate-03';out.mkdir();project=out/'project'
for name in ['src','tools','tests/frontend/phase2-rules']:shutil.copytree(old/name,project/name)
(project/'dist').mkdir()
p=project/'src/load/graph.bend';s=p.read_text();old='f_choose(KTerm, f_eq(tg(t), "Error"), u => f_choose(KTerm, String.is_empty(nm(t)), u => atom("Absent"), u => t), u => fpe_terms(ks(t)))';new='f_choose(KTerm, f_eq(tg(t), "Error"), u => f_choose(KTerm, String.is_empty(nm(t)), u => atom("Absent"), u => t), u => f_choose(KTerm, f_eq(tg(t), "ImportLaw"), u => kt("Error", "imported law fills require the canonical graph loader", 0, 0, Nil{}), u => fpe_terms(ks(t))))';assert s.count(old)==1;p.write_text(s.replace(old,new))
config={'project':str(project),'upstream':str(root/'selfhost/.bootstrap/upstream-phase8'),'profile':'equality','cpu':'2','jobs':1}
(out/'config.json').write_text(json.dumps(config,indent=2)+'\n')
(out/'plan.json').write_text(json.dumps({'kind':'phase14-imported-law-candidate','scope':'Finish legacy marker rejection in actual shared error walker; candidate02 preparation assertion failed before build.','consumedTool':str(pathlib.Path(__file__).resolve()),'sha256':hashlib.sha256(pathlib.Path(__file__).read_bytes()).hexdigest()},indent=2)+'\n')
(root/'selfhost/build/phase14/laws-candidate-02/failure.json').write_text(json.dumps({'complete':False,'stage':'prepare','error':'AssertionError: src/front/sugar.bend f_error_term no longer has old direct traversal expression; shared fpe_term is authoritative. No build/config existed.','consumedTool':str(root/'selfhost/tools/performance/phase14/laws-prepare-02.py')},indent=2)+'\n')
