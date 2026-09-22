#!/usr/bin/env python3
"""Static documentation checks. This is NOT an IBM i compiler/test runner."""
import json
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
errors = []
pages = [ROOT / 'index.md', *sorted((ROOT / 'guide').glob('*.md'))]
for page in pages:
    text = page.read_text()
    if not text.startswith('---\n'):
        errors.append(f'{page.name}: missing front matter')
    if text.count('```') % 2:
        errors.append(f'{page.name}: unbalanced code fences')
    links = re.findall(r'{%\s*link\s+(\S+)\s*%}', text)
    links += re.findall(r"{{\s*'([^']+)'\s*\|\s*relative_url\s*}}", text)
    for target in links:
        if not (ROOT / target.lstrip('/')).is_file():
            errors.append(f'{page.name}: missing link target {target}')

for path in (ROOT / 'examples').glob('*.json'):
    json.loads(path.read_text())

checks_page = (ROOT / 'guide/checks.md').read_text()
for path in sorted((ROOT / 'examples/sql').glob('0[1-5]-*.sql')):
    if f'```sql\n{path.read_text().rstrip()}\n```' not in checks_page:
        errors.append(f'{path.name}: displayed SQL differs from download')

for path in (ROOT / 'examples/rpg').glob('*.sqlrpgle'):
    if not path.read_text().startswith('**free\n'):
        errors.append(f'{path.name}: not fully free RPG')
    for n, line in enumerate(path.read_text().splitlines(), 1):
        if len(line) > 100:
            errors.append(f'{path.name}:{n}: exceeds 100 source columns')

# Credentials should never be embedded in the public starter.
for path in [*pages, *list((ROOT / 'examples').rglob('*'))]:
    if path.is_file() and re.search(r'https://hooks\.slack\.com/services/\S+',
                                    path.read_text()):
        errors.append(f'{path.name}: webhook URL found in public material')

if errors:
    raise SystemExit('\n'.join(errors))
print(f'PASS: {len(pages)} pages, local links, JSON, five SQL copies, RPG line lengths.')
print('IBM i compilation/execution and production behavior were not tested.')
