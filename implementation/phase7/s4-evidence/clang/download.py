import hashlib,json,pathlib,subprocess
base=pathlib.Path('/tmp/bend-s4-clang19'); evidence=base/'evidence'
packages=[]
for block in (evidence/'selected-packages-05.txt').read_text().strip().split('\n\n'):
 fields=dict(line.split(': ',1) for line in block.splitlines() if ': ' in line and not line.startswith(' '))
 packages.append(fields)
index=(evidence/'security-packages-05.data').read_bytes()
index_sha=hashlib.sha256(index).hexdigest()
assert index_sha+'   '+str(len(index))+' main/binary-amd64/Packages.xz' in (evidence/'security-inrelease-05.data').read_text()
with (evidence/'inrelease-verification.stdout').open('wb') as out, (evidence/'inrelease-verification.stderr').open('wb') as err:
 subprocess.run(['gpgv','--keyring','/usr/share/keyrings/debian-archive-keyring.gpg',str(evidence/'security-inrelease-05.data')],stdout=out,stderr=err,check=True)
rows=[]
for fields in packages:
 name=fields['Package']; snap=json.loads((evidence/(name+'-snapshot-07.json')).read_text())
 assert snap['binary_version']==fields['Version']
 sha1=next(row['hash'] for row in snap['result'] if row['architecture']=='amd64')
 url='https://snapshot.debian.org/file/'+sha1
 path=base/'packages'/pathlib.Path(fields['Filename']).name
 with (evidence/(name+'-download-08.stdout')).open('wb') as out, (evidence/(name+'-download-08.stderr')).open('wb') as err:
  result=subprocess.run(['curl','--fail','--location','--show-error','--max-time','90',url,'--output',str(path)],stdout=out,stderr=err)
 assert result.returncode==0,(name,result.returncode)
 data=path.read_bytes()
 assert len(data)==int(fields['Size']),name
 assert hashlib.sha256(data).hexdigest()==fields['SHA256'],name
 assert hashlib.sha1(data).hexdigest()==sha1,name
 rows.append({'package':name,'version':fields['Version'],'architecture':'amd64','bytes':len(data),'sha256':fields['SHA256'],'snapshotSha1':sha1,'url':url,'path':str(path),'depends':fields.get('Depends','')})
 (evidence/'package-manifest.json').write_text(json.dumps({'complete':len(rows)==4,'source':'Debian security signed InRelease + package index; same bytes downloaded from official Debian snapshot','indexSha256':index_sha,'packages':rows},indent=2)+'\n')
 print(name+' verified',flush=True)
