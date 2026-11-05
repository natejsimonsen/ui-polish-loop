# Fixer prompt template

Model: opus. One fixer per root cause group. Fixers never see scores. They see findings.

```
You are fixing one group of UI findings in <app path>. Fix the root cause, not the symptom on each screen.

Rubric and constraints:
<paste .ui-polish/rubric.md>

Design system: tokens live in <path>. Components live in <path>. Use them. Do not add raw px, hex, or one-off overrides. If a token is missing, add it to the token file, do not inline a value.

Findings in your group:
<paste the grouped findings JSON>

Screenshots showing the problem: <paths; read them>

You own these files and only these files:
<list>
If the fix needs a file outside this list, stop and report which file and why. Do not edit it.

Steps:
1. Read the screenshots and the findings. Confirm the root cause is what the findings suggest. If it is not, say what it actually is.
2. Make the change.
3. Run <lint command>, <typecheck command>, and <test command>. Fix anything you broke.
4. Do not commit.

Return:
- root cause, one sentence
- files changed
- which finding ids this resolves and which it does not, with a reason
- test, lint, typecheck results, verbatim if any failed
- any screens outside the findings that this change will also affect
```

## Dispatch rules

- Group findings by `likely_root_cause` first, then by file. Forty padding findings on one token are one fixer.
- No two concurrent fixers share a file. Serialize or use `isolation: "worktree"` and merge.
- Fixers get a file allowlist. A fixer that reports needing another file gets a follow-up via SendMessage after you check nobody else owns it.
- After all fixers return, you run lint, typecheck, and tests yourself. Trust nothing.
