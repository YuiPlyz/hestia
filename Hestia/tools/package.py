"""HESTIA manifest, exact URL inventory, and complete file-by-file delivery."""
from pathlib import Path
import json
import re
import zipfile

ROOT = Path(__file__).resolve().parents[1]
DEPENDENCIES = {
 'Main':['Importer','Config','State','Services','Connections','Logger','Notifications','Scheduler','GameAdapter','TaskManager','Navigator','ConfigStore','ConfigValidation','Interface','Hooks','Version'],
 'Interface':['ThemeManager','Widget'], 'GameAdapter':['Items','Weapons','Enemies','Locations','Structures'],
 'ScrapFarm':['FarmWorker','Utilities'], 'ItemFarm':['FarmWorker','Utilities'], 'FuelFarm':['FarmWorker','Utilities'],
 'Combat':['NPCTargeting','Weapons'], 'NPCTargeting':['Utilities','Enemies'], 'Movement':['Fly','Noclip'],
 'ESP':['ItemESP','MobESP','PlayerESP','StructureESP'], 'ConfigStore':['ConfigValidation'],
}
def files():
    return sorted(p for p in ROOT.rglob('*') if p.is_file() and not any(x in p.parts for x in ['.bin','.git','dist','__pycache__']))

def main():
    loader = (ROOT/'loader.lua').read_text(encoding='utf-8')
    repository = {}
    for key in ['Owner', 'Name', 'Channel', 'Directory']:
        match = re.search(r'\b'+key+r'\s*=\s*"([^"]*)"', loader)
        if not match:
            raise ValueError('Missing repository setting in loader.lua: '+key)
        repository[key] = match.group(1)
    directory = repository['Directory'].strip('/')
    base = f"https://raw.githubusercontent.com/{repository['Owner']}/{repository['Name']}/{repository['Channel']}/"
    if directory:
        base += directory+'/'
    modules = {}
    for folder in ['src','modules','ui','data']:
        for path in sorted((ROOT/folder).glob('*.lua')):
            if path.stem == 'Installer': continue
            name = ('UI'+path.stem) if folder == 'ui' and path.stem in ['Generator','Combat','Teleports'] else path.stem
            modules[name] = {'path':path.relative_to(ROOT).as_posix(), 'dependencies':DEPENDENCIES.get(name,[]), 'optional':folder=='modules'}
    manifest = {'name':'HESTIA','version':'1.0.0','modules':modules,'entrypoints':{'client':'client/Runtime.client.lua','server':'server/Runtime.server.lua'}}
    (ROOT/'manifest.json').write_text(json.dumps(manifest,indent=2)+'\n',encoding='utf-8')
    tree_paths = [p.relative_to(ROOT).as_posix() for p in files() if p.name not in ['TREE.md','RAW_URLS.md']]
    tree_paths += ['docs/TREE.md','docs/RAW_URLS.md']
    nested = {}
    for path in sorted(set(tree_paths)):
        node = nested
        for part in path.split('/'): node = node.setdefault(part,{})
    def tree(node, prefix=''):
        rows = []
        entries = sorted(node.items(), key=lambda pair:(bool(pair[1]),pair[0]))
        for i,(name,children) in enumerate(entries):
            last = i == len(entries)-1
            rows.append(prefix+('└── ' if last else '├── ')+name+('/' if children else ''))
            rows += tree(children,prefix+('    ' if last else '│   '))
        return rows
    (ROOT/'docs/TREE.md').write_text('# HESTIA repository tree\n\n```text\nHestia/\n'+'\n'.join(tree(nested))+'\n```\n',encoding='utf-8')
    tracked = files()
    urls = [base+p.relative_to(ROOT).as_posix() for p in tracked if p.suffix in ['.lua','.json','.md'] and p.name != 'RAW_URLS.md']
    location = f"`{repository['Owner']}/{repository['Name']}`, branch `{repository['Channel']}`, directory `{directory or '(repository root)'}`"
    (ROOT/'docs/RAW_URLS.md').write_text('# HESTIA raw URLs\n\nThese URLs become available after uploading the matching files to '+location+'.\n\n```text\n'+'\n'.join(urls)+'\n```\n',encoding='utf-8')
    tracked = files()
    dist = ROOT/'dist'
    dist.mkdir(exist_ok=True)
    with (dist/'HESTIA-FILES.md').open('w',encoding='utf-8') as output:
        output.write('# HESTIA complete project\n\nEvery project file is included below.\n\n')
        for path in tracked:
            ext = {'lua':'lua','json':'json','py':'python','md':'markdown'}.get(path.suffix[1:],'text')
            output.write('## FILE: '+path.relative_to(ROOT).as_posix()+'\n\n````'+ext+'\n'+path.read_text(encoding='utf-8')+'\n````\n\n')
    with zipfile.ZipFile(dist/'HESTIA.zip','w',zipfile.ZIP_DEFLATED) as archive:
        for path in tracked: archive.write(path,'Hestia/'+path.relative_to(ROOT).as_posix())
        archive.write(dist/'HESTIA-FILES.md','Hestia/HESTIA-FILES.md')
    print(f'HESTIA: {len(modules)} modules, {len(tracked)} project files; archive and complete source document generated.')

if __name__ == '__main__': main()
