"""Fail-closed observational policy for NEW paired JS coverage; no fixture execution."""
import re,json
OBSERVABLE=['status','phase','checked','typeAccepted','proofTrust','kernelChecked','unsafeDefinitions','exitCode','diagnostic','output','stdout','stderr','error','reason','signal','sourceFile']
HOST={'reference':{'executionArgs','executionMode'},'candidate':{'hostProvenance','runtimeNodeArgs','verdict'}}
ROW_FIELDS=['id','lane','namespace','negative','failureKind','status','evidence','reason']
ROW_ALLOWED=set(ROW_FIELDS)|{'ms','result','artifacts','replay'}
NA=re.compile(r"^Error: main's type .* cannot be printed(?: \(a function, a Type, an erased or dependent field\))?$")
BANNER='ALL PROOFS CHECK\nUse --verdict for mathematical validity.\n'
def exact(a,b):return json.dumps(a,sort_keys=True,separators=(',',':'))==json.dumps(b,sort_keys=True,separators=(',',':'))

def observe(pair,left,right,fixture,p):
 result={'id':pair['id'],'lane':pair['lane'],'referenceVerdict':left.get('status'),'candidateVerdict':right.get('status'),'accepted':False,'classification':'unexplained','errors':[],'referenceResult':left.get('result'),'candidateResult':right.get('result')}
 def need(ok,description):
  if not ok:result['errors'].append(description)
 for side,row in [('reference',left),('candidate',right)]:
  need(isinstance(row.get('result'),dict),side+' missing result');need(not(set(row)-ROW_ALLOWED),side+' unknown row keys '+str(sorted(set(row)-ROW_ALLOWED)))
  need(row.get('id')==fixture['id'] and row.get('lane')=='js',side+' row identity')
  need(row.get('negative') is False and row.get('failureKind') is None,side+' positive fixture metadata')
 if not isinstance(left.get('result'),dict) or not isinstance(right.get('result'),dict):return result
 a,b=left['result'],right['result']
 for key in ROW_FIELDS:need(exact(left.get(key),right.get(key)),'row field '+key)
 for key in OBSERVABLE:need(exact(a.get(key),b.get(key)),'observable field '+key)
 for side,r in [('reference',a),('candidate',b)]:
  unknown=set(r)-set(OBSERVABLE)-HOST[side];need(not unknown,side+' unknown result keys '+str(sorted(unknown)))
  argkey='executionArgs' if side=='reference' else 'runtimeNodeArgs'
  if argkey in r:need(r[argkey]==p['runtimeNodeArgs'],side+' runtime args')
  if side=='reference':
   if 'executionMode' in r:need(r['executionMode']=='js','reference execution mode')
  else:
   need(r.get('hostProvenance')==p['hostProvenance'],'candidate host provenance')
   if 'verdict' in r:need(r['verdict']==BANNER,'candidate extra verdict banner')
 need(pair.get('exactAgreement') is True and pair.get('semanticAgreement') is True,'legacy paired exact flags')
 need(pair.get('referenceVerdict')==left.get('status') and pair.get('candidateVerdict')==right.get('status'),'raw/paired verdict linkage')
 need(exact(pair.get('reference'),pair.get('candidate')),'complete legacy paired observations')
 status=left.get('status')
 if status==right.get('status')=='pass':
  for side,r in [('reference',a),('candidate',b)]:
   need(r.get('status')=='ok' and r.get('phase')=='runtime' and r.get('checked') is True and r.get('exitCode')==0,side+' checked successful execution')
   need(r.get('signal') is None and r.get('error') is None and r.get('reason') is None,side+' host process error')
   need(r.get('output')==r.get('stdout'),side+' combined output/stdout')
   need(r.get('stderr')=='',side+' combined-output stderr')
   # The immutable judge owns fixture newline/exit rendering; both raw verdicts
   # and its exact source are bound, and raw output remains unmodified here.
   need(r.get('executionArgs' if side=='reference' else 'runtimeNodeArgs')==p['runtimeNodeArgs'],side+' missing runtime flags')
  need(a.get('executionMode')=='js','missing reference execution mode');result['classification']='pass'
 elif status==right.get('status')=='not-applicable':
  for side,r in [('reference',a),('candidate',b)]:
   need(r.get('status')=='error' and r.get('phase')=='compile' and r.get('checked') is True and r.get('exitCode')==1,side+' NA phase/checked/exit')
   need(isinstance(r.get('diagnostic'),str) and bool(NA.fullmatch(r['diagnostic'])),side+' narrow unprintable-main diagnostic')
   need(r.get('output') is None and r.get('stdout') is None and r.get('stderr') is None,side+' unexpected NA runtime output')
   need(r.get('signal') is None and r.get('error') is None and r.get('reason') is None,side+' unexpected NA host error')
  result['classification']='not-applicable'
 else:
  result['classification']='paired-'+str(status) if status==right.get('status') else 'verdict-difference'
  need(False,'unaccepted fixture verdict')
 result['accepted']=not result['errors'];return result
