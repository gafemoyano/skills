#!/usr/bin/env python3
"""Link curated skills and synchronize always-on instructions. Python 3.9+."""
import argparse
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
START = '<!-- agent-kit:begin -->'
END = '<!-- agent-kit:end -->'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--home', type=Path, default=Path.home(),
                        help='Alternate home directory (for testing)')
    args = parser.parse_args()
    home = args.home.expanduser().resolve()
    skills = sorted(p.parent for p in (ROOT / 'skills').glob('*/SKILL.md'))
    # Shared discovery for Pi, Codex, and Amp; Claude uses its own location.
    links = [(home / folder / skill.name, skill)
             for folder in ('.agents/skills', '.claude/skills') for skill in skills]
    for dest, source in links:
        if dest.is_symlink() and dest.resolve() == source.resolve():
            continue
        if dest.exists() or dest.is_symlink():
            raise SystemExit(f'Conflict: {dest}; move it aside manually. Nothing changed.')

    sections = []
    for name in json.loads((ROOT / 'always-on.json').read_text()):
        if name not in {p.name for p in skills}:
            raise SystemExit(f'Unknown always-on skill: {name}')
        text = (ROOT / 'skills' / name / 'SKILL.md').read_text()
        sections.append(text.split('---', 2)[2].strip() if text.startswith('---\n') else text.strip())
    block = START + '\n\n' + '\n\n'.join(sections) + '\n\n' + END
    updates = []
    for relative in ('.pi/agent/AGENTS.md', '.codex/AGENTS.md',
                     '.claude/CLAUDE.md', '.config/amp/AGENTS.md'):
        dest = home / relative
        # Follow the active override instead, if one exists.
        override = dest.with_name('AGENTS.override.md')
        if dest.name == 'AGENTS.md' and override.exists():
            dest = override
        old = dest.read_text() if dest.exists() else ''
        if START in old or END in old:
            if old.count(START) != 1 or old.count(END) != 1 or old.index(START) > old.index(END):
                raise SystemExit(f'Malformed managed block in {dest}; nothing changed.')
            begin, finish = old.index(START), old.index(END) + len(END)
            new = old[:begin] + block + old[finish:]
        else:
            new = old + ('\n\n' if old else '') + block + '\n'
        updates.append((dest, old, new))

    # All conflict checks happen before any changes.
    for dest, source in links:
        if not dest.is_symlink():
            dest.parent.mkdir(parents=True, exist_ok=True)
            dest.symlink_to(source, target_is_directory=True)
            print(f'Linked {dest} -> {source}')
    for dest, old, new in updates:
        if old == new:
            continue
        dest.parent.mkdir(parents=True, exist_ok=True)
        if dest.exists():
            backup = dest.with_name(dest.name + '.pre-agent-kit.bak')
            if not backup.exists():
                backup.write_text(old)
        dest.write_text(new)
        print(f'Updated {dest}')
    print('Installed. Reload/restart agents to discover changes.')


if __name__ == '__main__':
    main()
