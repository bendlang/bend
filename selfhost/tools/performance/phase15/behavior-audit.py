import pathlib,json,hashlib,re,sys
root=pathlib.Path.cwd();validation=pathlib.Path(sys.argv[1]).resolve();out=pathlib.Path(sys.argv[2]).resolve();out.mkdir()
def read(p):return json.loads(p.read_text())
def ident(p):return {'file':str(p),'sha256':hashlib.sha256(p.read_bytes()).hexdigest()}
paired=read(validation/'selected/paired.json');reference=read(validation/'selected/reference.json');candidate=read(validation/'selected/candidate.json');workflow=read(validation/'report.json')
assert workflow['complete'] and len(paired['rows'])==58 and not paired['missing']
for report in [reference,candidate]:
 assert len(report['results'])==58 and report['finished'] and not report['changedInputs']
 assert not report['identity']['adapterChangedDuringRun'] and not report['identity']['changedArtifacts']
 assert all(not x['errors'] and x['stats']['timeouts']==0 and x['stats']['failures']==0 for x in report['workers'])
 assert not any(x['result']['status'] in ['timeout','unsupported','crash'] for x in report['results'])
axes=['status','phase','checked','typeAccepted','proofTrust','kernelChecked','unsafeDefinitions','exitCode','output']
rows=paired['rows'];assert all(all(x['reference'].get(k)==x['candidate'].get(k) for k in axes) for x in rows)
custom=[x for x in rows if x['id'].startswith('p15-behavior/')];assert len(custom)==38 and all(x['referenceVerdict']=='pass' and x['candidateVerdict']=='pass' for x in custom)
corpus=[x for x in rows if not x['id'].startswith('p15-behavior/')];assert len(corpus)==20
exactMissing={'import/cross_file_io.bend','import/cross_file_proof.bend','import/cycle_terminates.bend','import/diamond_dedup.bend','import/path_canonical.bend'}
for x in corpus:
 assert x['candidate']['phase']=='parse' and x['candidate']['status']=='error' and x['candidate']['checked']==False
 if x['id'] in exactMissing:assert x['exactAgreement']
exactControls={'missing-first.bend','missing-before-alias.bend','missing-parent-body.bend','missing-before-invalid.bend','nested-missing.bend','unicode-prefix-missing.bend','hyphen.bend','sub/parent.bend','valid-binder.bend','valid-underscore.bend','double-slash.bend'}
for x in custom:
 name=x['id'].removeprefix('p15-behavior/')
 if name in exactControls:assert x['exactAgreement'],x['id']
 if name=='bad-body-first.bend':
  strip=lambda s:'\n'.join(l for l in s.split('\n') if not re.match(r'^[ \t]*\|[ \t]*\^+[ \t]*$',l))
  assert strip(x['reference']['diagnostic'])==strip(x['candidate']['diagnostic'])
 if name=='duplicate-before-missing.bend':assert 'fresh alias' in x['candidate']['diagnostic'] and 'no such file' not in x['candidate']['diagnostic']
 if name=='invalid-before-missing.bend':assert 'an import path of plain names' in x['candidate']['diagnostic'] and 'no such file' not in x['candidate']['diagnostic']
report={'kind':'phase15-parser-load-scoped-gates','complete':True,'pass':True,'inputs':[ident(validation/'selected'/name) for name in ['paired.json','reference.json','candidate.json']]+[ident(validation/'report.json'),ident(pathlib.Path(__file__).resolve())],'observations':len(rows),'exact':sum(x['exactAgreement'] for x in rows),'strictDifferences':sum(not x['exactAgreement'] for x in rows),'behaviorAgreement':len(rows),'targetedCorpusObservations':len(corpus),'targetedExact':sum(x['exactAgreement'] for x in corpus),'externalControls':len(custom),'customDeclaredOraclesPass':len(custom),'strictWorkflowPass':workflow['pass'],'intendedCorpusDeltas':[{'id':x['id'],'lane':x['lane'],'required':{k:x['reference'].get(k) for k in axes},'exactExpectedWithoutCaretPatch':x['id'] in exactMissing} for x in corpus],'limitation':'The strict paired result remains failed because known diagnostic differences are retained. This scoped audit asserts behavior axes, explicit error ordering and exact named families without normalizing the strict oracle.'}
(out/'report.json').write_text(json.dumps(report,indent=2)+'\n');print(json.dumps({k:report[k] for k in ['complete','pass','observations','exact','strictDifferences','behaviorAgreement','targetedExact']}))
