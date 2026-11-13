---
name: pr-visual-proof
description: "When creating or updating a PR in an HTML/UI repository, include visual evidence of the affected UI before handing it off for review."
---

# Visual proof for UI PRs

PRs in HTML/UI repositories must include visual proof of visible changes.

- Capture the running UI after the final change. A screenshot is enough; use a short recording when interaction matters. Inspect it before attaching.
- Show the affected state. Include mobile or dark mode when relevant; before/after only when useful.
- Embed the evidence in the PR with a short caption. Use a reviewer-accessible attachment or repository asset, not a local path.
- Use safe fixture data; label mocks and never expose customer data or secrets.
- If nothing visible changed, say so briefly. If capture is blocked, state the blocker; don't claim visual verification.

Keep it small: useful proof, not a wall of text. Follow workspace/repo guidance for capture tools and artifact locations.
