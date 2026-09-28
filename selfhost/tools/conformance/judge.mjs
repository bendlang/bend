import {tidy,expectation} from './inventory.mjs';

// Exact text and exit behavior are intentional. A rejection of the wrong
// construct is not proof that a dependent/affine/termination rule was enforced.
export function rendered(result) {
  let output=tidy(result.diagnostic ?? result.output ?? ((result.stdout||'')+(result.stderr||'')));
  if(result.exitCode && !new RegExp(`(?:^|\\n)exit ${result.exitCode}$`).test(output)) {
    output=tidy(output+'\nexit '+result.exitCode);
  }
  return output;
}
const trustRejection = result => result.status==='error'&&result.phase==='verdict'
  &&result.checked===true&&result.typeAccepted===true&&result.proofTrust==='failed'&&result.exitCode===1;
export function judge(test,lane,result,capabilities) {
  if(result.status==='timeout'||result.status==='crash') return {status:result.status,reason:result.reason};
  if(result.status==='unsupported') return {status:'unsupported',reason:result.reason};
  if(lane==='check'&&!capabilities.check)return {status:'unsupported',reason:'Adapter has no complete checker.'};
  if(test.oracle==='acceptance') {
    if(!['parse','check'].includes(lane))return {status:'unsupported',reason:'Acceptance-only fixture supplies no execution oracle.'};
    if(test.accept) {
      const accepted=lane==='parse'?result.status==='ok'&&result.phase==='parse'
        :(result.status==='ok'&&result.phase==='check'&&result.checked===true&&result.typeAccepted!==false)||trustRejection(result);
      return accepted?{status:'pass',evidence:lane==='parse'?'frontend-acceptance':'checker-acceptance',oracle:'acceptance'}
        :{status:'fail',reason:'Expected validated acceptance.',oracle:'acceptance'};
    }
    if(!test.rejectPhase)return {status:'fail',reason:'Acceptance-only negative requires an explicit rejection phase.',oracle:'acceptance'};
    if(test.rejectPhase==='verdict')return trustRejection(result)?{status:'pass',evidence:'proof-trust-rejection',oracle:'acceptance'}:{status:'fail',reason:'Expected proof-trust refusal after type acceptance.',oracle:'acceptance'};
    if(result.typeAccepted===true&&test.rejectPhase==='check')return {status:'fail',reason:'Type acceptance is not a checker rejection.',oracle:'acceptance'};
    if(result.status!=='error'||result.phase!==test.rejectPhase||result.exitCode!==1||(['check','compile','runtime'].includes(test.rejectPhase)&&result.checked!==true))return {status:'fail',reason:'Expected rejection phase/checked/exit evidence differs.',oracle:'acceptance'};
    return {status:'pass',evidence:['parse','load'].includes(result.phase)?'frontend-rejection':result.phase==='check'?'checker-rejection':result.phase+'-rejection',oracle:'acceptance'};
  }
  if(lane==='parse') {
    if(test.negative) return {status:'observed',reason:'Negative parse observations do not establish checker conformance.'};
    return result.status==='ok'&&result.phase==='parse' ? {status:'pass'} : {status:'fail',reason:'Positive source did not parse.'};
  }
  if(lane==='check') {
    if(test.negative) {
      if(result.status!=='error') return {status:'fail',reason:'Expected rejection; program was accepted.'};
      if(rendered(result)!==test.expected) return {status:'fail',reason:'Diagnostic/exit mismatch (unrelated rejection is not a pass).'};
      if((test.failureKind??expectation(test.expected).failureKind)==='proof-trust')return trustRejection(result)?{status:'pass',evidence:'proof-trust-rejection'}:{status:'fail',reason:'Expected proof-trust refusal after type acceptance.'};
      // Exact parser diagnostics can match a parser-negative fixture, but are
      // separately labeled and never counted as successful type/proof checking.
      if(result.phase==='parse'||result.phase==='load') return {status:'pass',evidence:'frontend-rejection'};
      if((result.phase==='compile'||result.phase==='runtime')&&result.checked===true) return {status:'pass',evidence:result.phase+'-rejection'};
      if(result.phase!=='check'||result.checked!==true||result.typeAccepted===true) return {status:'fail',reason:'No evidence that the checker rejected this program.'};
      return {status:'pass',evidence:'checker-rejection'};
    }
    if(result.status!=='ok'||result.phase!=='check'||result.checked!==true||result.typeAccepted===false) return {status:'fail',reason:'Positive source was not validated.'};
    if(!test.main && rendered(result)!==test.expected) return {status:'fail',reason:'Declaration/goal output mismatch.'};
    return {status:'pass',evidence:'checker-acceptance'};
  }
  if(test.negative) {
    if(result.status!=='error'||rendered(result)!==test.expected)return {status:'fail',reason:'Expected rejection diagnostic/exit mismatch.'};
    if((test.failureKind??expectation(test.expected).failureKind)==='proof-trust')return trustRejection(result)?{status:'pass',evidence:'proof-trust-rejection'}:{status:'fail',reason:'Expected proof-trust refusal after type acceptance.'};
    if(result.phase==='parse'||result.phase==='load')return {status:'pass',evidence:'frontend-rejection'};
    if(result.checked!==true)return {status:'fail',reason:'No evidence that the checker validated or rejected this program.'};
    if(result.phase==='check'&&result.typeAccepted===true)return {status:'fail',reason:'Type acceptance is not a checker rejection.'};
    if(['check','compile','runtime'].includes(result.phase))return {status:'pass',evidence:(result.phase==='check'?'checker':result.phase)+'-rejection'};
    return {status:'fail',reason:'Unknown rejection phase.'};
  }
  if(['js','native','metal','cuda'].includes(lane)&&result.checked===true&&result.status==='error'
    &&result.phase==='compile'&&/^Error: main's type .* cannot be printed(?: \(a function, a Type, an erased or dependent field\))?$/.test(tidy(result.diagnostic||''))) {
    return {status:'not-applicable',reason:'Upstream gate exempts unprintable main types from compiled execution.'};
  }
  if(result.status!=='ok'&&result.phase!=='runtime') return {status:'fail',reason:'Compilation failed.'};
  if(rendered(result)!==test.expected) return {status:'fail',reason:'Output/exit mismatch.'};
  if((lane==='metal'||lane==='cuda')&&result.hardwareExecuted!==true) return {status:'fail',reason:'No evidence of execution on the requested GPU backend.'};
  return {status:'pass',evidence:result.checked?'checked-execution':'unchecked-execution'};
}
