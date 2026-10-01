// Private entry proof. Installed only inside a completely guarded, synchronous,
// scalar-input region whose entire residual source graph was proved pure.
let regionProof=null;
function regionProofCovers(names){
  const proof=regionProof;if(proof===null)return false;
  for(let i=0;i<names.length;i++)if(proof[names[i]]!==true)return false;
  return true;
}
function regionProofOpen(names){
  const previous=regionProof;
  if(previous===null){
    const proof={__proto__:null};
    for(let i=0;i<names.length;i++)proof[names[i]]=true;
    regionProof=proof;
  }
  return previous;
}
function regionProofClose(previous){regionProof=previous;}
