from pathlib import Path
import hashlib,json,subprocess,os
R=Path.cwd();E=R/'implementation/phase22/context-evidence';sha=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
old=json.loads((E/'selection-draft-02.json').read_text()); source=R/old['finalSource'];api=old['finalApiSha256'];commit='1e640798c7b74c32a1d3f3335727d7be918795b9'
roots=sorted(x.relative_to(R).as_posix() for x in (R/'selfhost/build/phase22').iterdir())
files=set()
for directory in ['design/phase22','experiments/phase22','implementation/phase22','selfhost/tools/performance/phase22']:
 files.update(x.relative_to(R).as_posix() for x in (R/directory).iterdir() if x.is_file())
outside=['implementation/phase22/context-evidence/README.md','implementation/phase22/context-evidence/preservation.json','implementation/phase22/context-evidence/preservation.md','implementation/phase22/context-evidence/recovery-final-01.json','implementation/phase22/context-evidence/recovery-process-final-01.json','implementation/phase22/context-evidence/recovery-receipt-final-01.json','implementation/phase22/context-evidence/capture-process-final-01.json','implementation/phase22/context-evidence/prepare-process-final-01.json','implementation/phase22/context-evidence/selection-review-final-01.json','implementation/phase22/context-evidence/inventory-review-final-01.json','experiments/PRESERVATION.md']
files.update(x.relative_to(R).as_posix() for x in E.iterdir() if x.is_file() and x.relative_to(R).as_posix() not in outside and x.name not in ['selection-proposal.json','root-freeze.json','root-freeze-proposal-02.json'])
project=sorted(x.relative_to(source).as_posix()for x in source.rglob('*')if x.is_file());assert len(project)==215
for n in project:
 assert sha(source/n)==sha(R/'selfhost'/n),n
 files.add('selfhost/'+n)
owned=subprocess.check_output(['git','diff-tree','--no-commit-id','--name-only','-r',commit],text=True).splitlines();assert len(owned)==314
files.update(owned);files.update(old['extraFiles']['final'])
# Old estimate selection may reference only existing historical drafts. Keep them.
files.difference_update(outside)
files.update(x.relative_to(R).as_posix() for x in (R/'selfhost/dist/release-lineage').iterdir() if x.is_file())
files.update(['selfhost/dist/release.json','selfhost/dist/typed-api.mjs'])
assert not any((x.startswith('selfhost/dist/release-history/') and not x.startswith('selfhost/dist/release-history/44094e58cb0ef033e2c08c2827565e859c3594b3136868d4f821262145aea7f0/')) or x.startswith(('experiments/phase6/','implementation/phase6/','selfhost/tools/performance/phase6/')) for x in files)
assert all((R/x).is_file() for x in files)
proposal_rel='implementation/phase22/context-evidence/root-freeze-proposal-02.json'
selection={k:v for k,v in old.items() if k not in ['kind','final','captureAuthorized','allProducersClosed','extraTrees','extraFiles','outsideImmutableInputs','scope']}
selection['excludedTrees']=[x for x in selection['excludedTrees'] if x!='selfhost/dist/release-history']+['selfhost/dist/release-history/'+x for x in ['40c8f7f3b7cd0e96aef57d7d574ebfd85607cd4e096909d083b450b4d973362c','66d6ce45c0c6ea8947190ff210274f1e6f0c7bf85f7ad3f215076f8820acd7c7','9b20de5032e306a0b7ee2686a1cc79452f81fcb282ff6419a0d1ad5c4b5716b6','a15d150a920b89d9c0781372356424e559edabef3246ca281741069b0fe739b6']]
selection.update(kind='phase22-final-exact-selection',final=True,captureAuthorized=False,allProducersClosed=True,releaseCommit=commit,archiveFormat={'container':'tar','compression':'xz','preset':9,'dictionaryBytes':67108864,'check':'CRC64'},extraTrees={'experiments':roots,'final':[]},extraFiles={'experiments':[],'final':sorted(files|{proposal_rel})},outsideImmutableInputs=outside,scope='Every named closed Phase22 producer, failed attempt and raw observation; installed215 source members and314-file committed release membership; exact prior fixture dependencies. Capture still requires root freeze authorization and independent prepared-inventory review. No omitted logical payload.')
sel=E/'selection-proposal.json';assert not sel.exists();sel.write_text(json.dumps(selection,indent=2)+'\n')
start=json.loads((R/'selfhost/build/phase22/start-state-01.json').read_text());status=subprocess.check_output(['git','status','--short','--untracked-files=all'],text=True);statusmap={line[3:]:line[:2] for line in status.splitlines()}
for row in start['unrelatedPhase6']:
 assert sha(R/row['path'])==row['sha256'] and statusmap.get(row['path'])==row['status'],row['path']
history=[line[3:] for line in start['status'].splitlines()if line[3:].startswith('selfhost/dist/release-history/')];assert len(history)==28
for name in history:assert statusmap.get(name)=='??',name
critical=sorted(files|{sel.relative_to(R).as_posix()}|{x.relative_to(R).as_posix()for x in (R/'selfhost/build/phase22').glob('*freeze*.json')}|{'selfhost/build/phase22/start-state-01.json','selfhost/build/phase22/context-source-17/manifest.json','selfhost/build/phase22/context-source-17/parent.json','selfhost/build/phase22/context-build-16/attempt.json','selfhost/build/phase22/context-build-16/build.json','selfhost/build/phase22/context-build-16/validation-001/report.json','selfhost/build/phase22/context-installation-01/report.json','selfhost/build/phase22/context-smoke-01/checks/report.json'})
freeze={'kind':'phase22-root-freeze-proposal','authorized':False,'allProducersClosed':True,'anchorStatus':'installed-contextual-parser-release','releaseCommit':commit,'baselineCommit':old['baselineCommit'],'finalSource':old['finalSource'],'finalAttempt':old['finalAttempt'],'finalApiSha256':api,'sourceMembers':215,'sourceBytes':sum((source/n).stat().st_size for n in project),'inputs':[{'path':n,'sha256':sha(R/n)}for n in critical],'additionalFiles':[],'protectedPhase6':start['unrelatedPhase6'],'preexistingHistoryExcluded':[{'path':n,'sha256':sha(R/n),'status':statusmap[n]}for n in history],'outsideImmutableInputs':outside,'authorizationPending':'Root grant after exact selection review; prepared inventory must be independently reviewed before capture. All root compiler/docs producers closed at checkpoint1e640798; only approved preservation artifacts remain.','diskPolicy':{'codec':'xz','provisionalCompressedBytes':23465700,'capsulePlanningBytes':40000000,'partPayloadLimit':38000000,'retainedPayloadLimit':8000000,'sourceReconstructionBytes':sum((source/n).stat().st_size for n in project),'serialOrder':['capture','independent bounded recovery','Git archive commit'],'freeBytesObserved':os.statvfs(R).f_bavail*os.statvfs(R).f_frsize}}
p=R/proposal_rel;assert not p.exists();p.write_text(json.dumps(freeze,indent=2)+'\n')
print(json.dumps({'selection':str(sel.relative_to(R)),'selectionSha256':sha(sel),'rootFreezeProposal':proposal_rel,'rootFreezeProposalSha256':sha(p),'exactBuildEntries':len(roots),'additionalFiles':len(selection['extraFiles']['final']),'frozenInputs':len(critical),'protectedPhase6':len(start['unrelatedPhase6']),'excludedHistoricalPaths':len(history),'sourceMembers':len(project),'sourceBytes':freeze['sourceBytes']}))
