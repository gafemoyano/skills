# Personal agent kit

Curated Markdown skills and always-on principles for gafemoyano.

## Install on another machine

Requires Git and Python 3.9+:

```sh
git clone git@github.com:gafemoyano/agent-kit.git ~/agent-kit
cd ~/agent-kit
python3 scripts/install.py
```

After pulling updates or adding skills, run the installer again. It is idempotent: it links every skills/*/SKILL.md directory into ~/.agents/skills (Pi, Codex, Amp) and ~/.claude/skills. Requires agent versions supporting these locations. Existing unrelated skills are untouched; conflicting names fail safely.

## Always-on versus conditional

Skills normally load only when relevant. Removing disable-model-invocation enables automatic selection, not guaranteed loading.

always-on.json selects skill bodies to embed into:
- Pi: ~/.pi/agent/AGENTS.md
- Codex: ~/.codex/AGENTS.md
- Claude Code: ~/.claude/CLAUDE.md
- Amp: ~/.config/amp/AGENTS.md

Existing AGENTS.override.md files take precedence where applicable. Only the agent-kit marked block is updated; existing content is preserved. Before the first modification of an existing instruction file, the installer saves a .pre-agent-kit.bak copy.

The testing principle is always-on. Design red flags is conditional.

## Add skills

Ask an agent to use the maintain-agent-kit skill, or:

1. Create skills/<name>/SKILL.md with name and description frontmatter.
2. Optionally add supporting references/ files and link them from SKILL.md.
3. For guidance that must be loaded every session, add its name to always-on.json.
4. Run:
   ```sh
   python3 -m unittest discover -s tests
   python3 scripts/install.py
   ```
5. Commit and push to sync other machines, then pull and reinstall there.

In Pi run /reload. Restart other agents to ensure discovery.

## Provenance

The initial design-red-flags and testing texts were supplied by the user from an unspecified third-party source. Upstream URL, author, and license are pending. No ownership or redistribution license is asserted for that text. Keep this repository private pending a license review.

## Uninstall

Remove only symlinks pointing into this checkout and the <!-- agent-kit:begin --> through <!-- agent-kit:end --> blocks in personal instruction files. The installer intentionally does not prune links for deleted/renamed skills; remove those links explicitly.
