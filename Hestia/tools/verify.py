"""Compile all HESTIA Luau, validate module wiring and run behavioral regression tests."""
from pathlib import Path
import json
import re
import subprocess
import sys

ROOT = Path(__file__).resolve().parents[1]
manifest = json.loads((ROOT/'manifest.json').read_text())
modules = manifest['modules']
paths = {entry['path'] for entry in modules.values()}
errors = []
for name, entry in modules.items():
    if not (ROOT/entry['path']).is_file(): errors.append('Missing module '+name)
    for dependency in entry.get('dependencies',[]):
        if dependency not in modules: errors.append('Unknown dependency '+dependency)

visiting, visited = set(), set()
def visit(name):
    if name in visiting: raise ValueError('Dependency cycle: '+name)
    if name in visited: return
    visiting.add(name)
    for dependency in modules[name].get('dependencies',[]): visit(dependency)
    visiting.remove(name)
    visited.add(name)
for name in modules: visit(name)

sources = sorted(ROOT.rglob('*.lua'))
for path in sources:
    text = path.read_text(encoding='utf-8')
    for imported in ([] if 'tests' in path.parts else re.findall(r':Import\("([^"\n]+)"\)', text)):
        if imported not in modules and imported not in paths: errors.append(f'{path.name}: unknown import {imported}')
    if re.search(r'getgenv\s*\(|gethui\s*\(|sethiddenproperty\s*\(|fireproximityprompt\s*\(|game:HttpGet\s*\(',text):
        errors.append(f'{path.name}: unsupported runtime API')

compiler = ROOT/'tools/.bin/luau-compile.exe'
runtime = ROOT/'tools/.bin/luau.exe'
if not compiler.exists() or not runtime.exists():
    sys.exit('Install official Luau binaries in tools/.bin first; see README.')
for path in sources:
    result = subprocess.run([str(compiler),str(path)],capture_output=True,text=True)
    if result.returncode: errors.append(result.stderr)
if errors:
    print('\n'.join(errors)); sys.exit(1)
print(f'HESTIA: compiled {len(sources)} files; {len(modules)} modules and all literal imports validated.',flush=True)
subprocess.run([str(runtime), str(ROOT/'tests/core.spec.lua')], check=True, cwd=ROOT)
