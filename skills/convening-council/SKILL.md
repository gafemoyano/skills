---
name: convening-council
description: "Convenes three independent models to review code or advise on a decision, reconciles their findings, and tracks review rounds. Use when the user asks for council or a multi-model council review."
license: MIT
---

# Council

Bring three independent models to the user's request. You own the conclusion, implementation, and verification; delegates supply evidence, not votes that override your judgment.

## Prepare the question

- State the goal, scope, constraints, and the decision or change being reviewed. For code, identify the exact diff and base revision, including uncommitted changes.
- Before a code audit, address known in-scope issues and outstanding actionable PR feedback, then run relevant checks. Review the updated implementation, not problems you already intend to fix. Skip fixes to code the user explicitly wants to discard. A read-only review request stays read-only.
- For design advice, give the alternatives and tradeoffs without implying a preferred answer. Do not implement anything unless the user's request includes implementation.

## Select and launch the council

Use the members the user names. Otherwise use one current flagship from each of Anthropic (Claude Opus), OpenAI (GPT Sol), and Google (Gemini), with high reasoning effort where supported. Resolve exact model IDs from the harness's available-model list; do not guess IDs or enable premium modes. These are the default council families, not permission to substitute another provider.

Use native delegation tools with explicit model selection, launching the three reviews in parallel. In Amp, discover models with `list_agent_modes`. Use model-selectable subagents if available; otherwise use three independent-review threads with explicit `agent_mode` values. Do not use three same-model subagents and call them a multi-provider council. If a requested member or provider is unavailable, report the gap and ask before proceeding with a reduced or different council.

Each delegate gets the same request, scope, and evidence. Include relevant files, checks already run, known limitations, and concrete questions. Ask for independently reasoned findings; do not show other delegates' conclusions before their first responses. Keep delegates read-only and tell them not to delegate further.

When delegates have separate checkouts, give them the exact reviewed state. A branch name or commit hash does not transfer local work. Use the harness's file-transfer tools for unpushed commits, diffs, or required fixtures, and identify the repository and base revision. Keep implementation and verification in the original checkout. Choose one completion path: request replies or wait for completion, not both.

For code reviews, ask each delegate for:

- Concrete findings with severity, file/line references, the failing scenario, and the smallest useful fix.
- Missing evidence or checks that could change their conclusion.
- A score out of 10 and whether any blocking issue remains. Scores summarize a review; they are not a target to optimize.

For advice, ask for a recommendation, its tradeoffs, and what evidence would favor a different choice. Scores are unnecessary.

## Reconcile and iterate

Read all responses. Verify consequential claims against the code, requirements, or authoritative sources. Deduplicate findings and distinguish agreement, disagreements, and uncertainty. A majority opinion is not proof. Explain why you accept or reject a recommendation.

If implementation is authorized, make accepted in-scope changes yourself and run relevant checks. Request a fresh review of the updated state from the same council after substantive fixes. Each complete review pass is one round; keep actual scores from every round and write `no score` when a delegate omits one. Mark failed or missing reviews explicitly rather than implying unanimity.

Stop when no substantiated in-scope blocker remains. Do not chase perfect scores or add unrelated cleanup to satisfy a delegate. If reviews repeat without new evidence or a disagreement needs a user decision, report the unresolved point and stop for that decision rather than looping indefinitely.

## Report

Lead with the conclusion, accepted findings, verification, and unresolved risks. Identify the actual models used. For a code review, include the round history:

| Delegate | Round 1 | Round 2 |
| --- | --- | --- |
| Actual model ID | 7/10 | 9/10 |

Use only rounds and scores that actually occurred. For advice, report recommendations and disagreements instead of a score table.

If the task includes an authorized PR creation or description update, add a `## Council review` section with the round count and table. Read the current description first and preserve others' content. Do not post a separate review-summary comment. Otherwise report in the final reply; requesting council alone does not authorize changing a PR, committing, or pushing.
