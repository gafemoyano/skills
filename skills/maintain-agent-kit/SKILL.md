---
name: maintain-agent-kit
description: "Add or update personal skills, references, or always-on principles in gafemoyano/agent-kit and install them across Pi, Codex, Claude Code, and Amp. Use when the user pastes a skill or asks to maintain their personal agent guidance."
---

# Maintain personal agent guidance

This skill lives in the personal agent-kit Git repository. Resolve the repository root two directories above this skill directory, following symlinks. Do not assume the checkout is always at ~/agent-kit.

1. Read README.md and AGENTS.md at the repository root.
2. Put each skill in skills/<name>/SKILL.md with matching lowercase-hyphen name and a clear description of when it applies. Preserve supplied instructions; record upstream attribution/license if known. Ask for missing provenance before publishing externally.
3. Remove disable-model-invocation when automatic selection is desired. Automatic selection is not always-on: only add a skill name to always-on.json when the user wants its full text included in every session.
4. Keep supplementary Markdown in that skill's references/ directory and link to it with reading instructions.
5. Run python3 -m unittest discover -s tests, then python3 scripts/install.py. The installer discovers all skills automatically; do not maintain a separate skill link list.
6. Do not overwrite conflicting files or links. Explain any conflict. Preserve existing personal instructions outside the managed block.
7. Report changed paths and remind the user to reload/restart agents. Commit/push only when requested or authorized by the current task.
