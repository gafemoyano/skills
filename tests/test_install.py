import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


class InstallerTests(unittest.TestCase):
    def run_install(self, home):
        return subprocess.run(
            [sys.executable, str(ROOT / 'scripts/install.py'), '--home', str(home)],
            text=True, capture_output=True)

    def test_install_preserves_instructions_and_is_idempotent(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            existing = home / '.claude/CLAUDE.md'
            existing.parent.mkdir(parents=True)
            existing.write_text('Keep my existing rules.\n')
            result = self.run_install(home)
            self.assertEqual(result.returncode, 0, result.stderr)
            first = existing.read_text()
            self.assertTrue(first.startswith('Keep my existing rules.\n'))
            self.assertIn('# Test Behavior, Not Implementation', first)
            self.assertNotIn('# Design red flags', first)
            self.assertEqual(existing.with_name('CLAUDE.md.pre-agent-kit.bak').read_text(),
                             'Keep my existing rules.\n')
            for skill in (ROOT / 'skills').iterdir():
                for folder in ('.agents/skills', '.claude/skills'):
                    self.assertEqual((home / folder / skill.name).resolve(), skill)
            result = self.run_install(home)
            self.assertEqual(result.returncode, 0, result.stderr)
            self.assertEqual(existing.read_text(), first)
            self.assertNotIn('Updated', result.stdout)

    def test_conflict_changes_nothing(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            conflict = home / '.agents/skills/design-red-flags'
            conflict.mkdir(parents=True)
            (conflict / 'mine.txt').write_text('keep')
            self.assertNotEqual(self.run_install(home).returncode, 0)
            self.assertEqual((conflict / 'mine.txt').read_text(), 'keep')
            self.assertFalse((home / '.claude').exists())
            self.assertFalse((home / '.pi').exists())

    def test_active_override_and_malformed_block(self):
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            override = home / '.codex/AGENTS.override.md'
            override.parent.mkdir(parents=True)
            override.write_text('Override rules.\n')
            self.assertEqual(self.run_install(home).returncode, 0)
            self.assertIn('# Test Behavior, Not Implementation', override.read_text())
            self.assertFalse((home / '.codex/AGENTS.md').exists())
        with tempfile.TemporaryDirectory() as tmp:
            home = Path(tmp)
            dest = home / '.claude/CLAUDE.md'
            dest.parent.mkdir(parents=True)
            dest.write_text('<!-- agent-kit:begin -->')
            self.assertNotEqual(self.run_install(home).returncode, 0)
            self.assertFalse((home / '.agents').exists())
            self.assertEqual(dest.read_text(), '<!-- agent-kit:begin -->')
