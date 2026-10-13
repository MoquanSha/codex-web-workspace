"""Check portable package integrity without exposing secret values."""
from pathlib import Path
import argparse, hashlib, json, re, sys

ROOT = Path(__file__).resolve().parents[1]
SECRET_PATTERNS = {
    'github-token': r'\b(?:gh[pousr]_[A-Za-z0-9]{30,}|github_pat_[A-Za-z0-9_]{30,})\b',
    'api-key': r'\bsk-(?:proj-|svcacct-)?[A-Za-z0-9_-]{32,}\b',
    'aws-key': r'\bAKIA[A-Z0-9]{16}\b',
    'private-key': r'-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----',
    'jwt': r'\beyJ[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]{15,}\.[A-Za-z0-9_-]{15,}\b',
}
DENIED_NAMES = {'auth.json','credentials.json','cookies.txt','.env'}
SKIP_PARTS = {'.git','.venv','node_modules','__pycache__'}

def files():
    for p in ROOT.rglob('*'):
        parts=p.relative_to(ROOT).parts
        if p.is_file() and parts[0] not in {'materials','runtime','tmp'} and not any(x in SKIP_PARTS for x in parts):
            yield p

def main():
    ap=argparse.ArgumentParser(); ap.add_argument('--yaml',action='store_true'); args=ap.parse_args()
    errors=[]; warnings=[]
    for name in ['AGENTS.md','memory/INDEX.md','memory/PROFILE.md','memory/durable/personal-profile-index.md','memory/durable/personal-dialogue-profile.md','references/paper-deepread-standard.md','environment/skill-catalog.json']:
        if not (ROOT/name).is_file() or (ROOT/name).stat().st_size==0: errors.append('Missing required file: '+name)
    agents=ROOT/'AGENTS.md'
    if agents.exists() and agents.stat().st_size>32768: errors.append('AGENTS.md exceeds default 32 KiB instruction budget')
    yaml=None
    if args.yaml:
        import yaml
    catalog=json.loads((ROOT/'environment/skill-catalog.json').read_text('utf-8'))
    names=set()
    for entry in catalog:
        p=ROOT/entry['path']
        if not p.is_file(): errors.append('Missing skill: '+entry['path']); continue
        text=p.read_text('utf-8-sig')
        fm=re.match(r'---\s*\n(.*?)\n---',text,re.S)
        if not fm: errors.append('No frontmatter: '+entry['path']); continue
        if not entry['description']: errors.append('No skill description: '+entry['path'])
        if yaml:
            try:
                data=yaml.safe_load(fm.group(1))
                if not isinstance(data,dict) or not data.get('name') or not data.get('description'): errors.append('Invalid metadata: '+entry['path'])
            except yaml.YAMLError: errors.append('Invalid YAML: '+entry['path'])
        if entry['mode']=='repo-skill':
            if entry['name'] in names: errors.append('Duplicate repo skill name: '+entry['name'])
            names.add(entry['name'])
    manifest=json.loads((ROOT/'environment/source-manifest.json').read_text('utf-8'))
    for entry in manifest['files']:
        p=ROOT/entry['destination']
        if not p.exists(): errors.append('Missing exported resource: '+entry['destination']); continue
        expected=entry.get('exported_sha256',entry['sha256'])
        if hashlib.sha256(p.read_bytes()).hexdigest()!=expected: errors.append('Resource changed without manifest update: '+entry['destination'])
    count=0; total=0
    for p in files():
        rel=p.relative_to(ROOT).as_posix(); data=p.read_bytes(); count+=1; total+=len(data)
        if p.name in DENIED_NAMES or (p.name.startswith('.env.') and p.name!='.env.example'): errors.append('Credential filename: '+rel)
        if p.suffix in {'.pem','.key','.p12','.sqlite','.db'}: errors.append('Sensitive/runtime file: '+rel)
        if p.name in {'AGENTS.md','AGENT.md','AGENTS.override.md'} and rel!='AGENTS.md': errors.append('Nested instruction file: '+rel)
        # ASCII scan also covers binary strings without printing their values.
        text=data.decode('utf-8',errors='ignore')
        if p.name != 'validate_bundle.py':
            for label,pattern in SECRET_PATTERNS.items():
                if re.search(pattern,text): errors.append('Potential '+label+' in '+rel)
        if p.suffix=='.sh' and b'\r\n' in data: warnings.append('CRLF shell script: '+rel)
    print(json.dumps({'status':'failed' if errors else 'passed','repo_skills':len(names),'plugin_references':sum(e['mode']=='plugin-reference' for e in catalog),'files':count,'bytes':total,'errors':errors,'warnings':warnings,'limit':'Static structure, hashes and known secret patterns only; not proof of cloud service authorization or model behavior.'},ensure_ascii=False,indent=2))
    return bool(errors)

if __name__=='__main__': sys.exit(main())
