---
name: ui-polish-loop
description: Iterative UI/UX polish loop. Headless screenshots of every screen, state, and flow; blind Opus raters score isolated chunks and cross-screen consistency against a user-defined rubric; Opus fixers address root causes; repeat with fresh raters until the rubric is met or the loop plateaus. Use when the user says "polish the UI", "rate the UX", "make the app look consistent", "UI audit loop", or /ui-polish-loop. Expensive. Never auto-trigger.
argument-hint: "[app-dir|url] [--scope flow,flow] [--max-rounds N] [--viewports desktop,mobile] [--budget N-agents]"
disable-model-invocation: true
metadata:
  author: Nate Simonsen
---

# UI Polish Loop

Screenshot everything, let blind raters score it, fix root causes, re-rate with fresh eyes. Stop on a pass or a plateau, never on hope.

Hard rules:

- Headless only. Never bring a browser or app window to the foreground.
- Raters never see prior scores, prior findings, or the diff. Fresh agent every round.
- Fixers fix root causes (a token, a shared component), never one screen at a time.
- Nothing is committed without asking.
- If a `delegation` skill is installed, load it before the first fan-out.

## Arguments

Parse `$ARGUMENTS`:

- `app-dir` or `url`: what to drive. If omitted, infer from cwd and the `run` skill.
- `--scope a,b`: restrict to named flows. Default is everything in the inventory.
- `--max-rounds N`: default 4.
- `--viewports`: default `desktop,mobile`. Add `tablet` on request.
- `--budget N`: max subagent calls for the whole run. Default 150. Stop and report when hit.

## Phase 0: Define the target (blocking)

Ask once, with AskUserQuestion, before any capture:

1. Design philosophy. Offer: minimal and clean; elegant and expressive; dense and utilitarian; playful. Ask for one or two reference apps.
2. Palette and density. Existing design system tokens, or free hand?
3. Which dimensions must reach 10: usability, consistency, beauty. Recommend usability and consistency required, beauty needs human sign-off.
4. Hard constraints: must keep brand colors, must keep layout, cannot touch X.

Write the answers into `.ui-polish/rubric.md` using `references/rubric-template.md`. Every rater and fixer gets this file verbatim. Without it, the scores are noise.

## Phase 1: Inventory

Before any rating:

1. Boot the app headless. Use the `run` skill if a project skill exists. Record the URL, login steps, and any seed data command in `.ui-polish/setup.md`.
2. Enumerate routes and screens from the router, sitemap, or a headless crawl. Write `.ui-polish/inventory.md`: one line per screen, grouped into flows (signup, checkout, settings...).
3. For each screen, list the states to capture: default, empty, loading, error, long content, and any modal or drawer it opens.
4. Pick the design system, if one exists. Note where tokens live. Fixers must use them.

Show the inventory to the user. This is the finish line. Do not skip the review because the list is long.

## Phase 2: Capture

Use `scripts/capture.sh` (bash wrapper over headless Playwright). It freezes time, disables animations, pins device scale factor, forces reduced motion, and never opens a window. Pass `--url` for one page or `--steps` with a JSON step file per flow. See `references/capture.md`.

Per screen and viewport, save to `.ui-polish/round-N/<flow>/<screen>-<state>-<viewport>.png`:

- Full page screenshot.
- One screenshot per interactive element in hover and focus state, when the element has such a state.
- A short video for any transition or multi-step interaction.
- An axe accessibility report alongside each screen (pass `--axe`; needs `@axe-core/playwright` installed).

Also capture a dark-mode variant when the app supports one.

Keep naming identical across rounds so pixel diffs line up.

## Phase 3: Rate

Two rater types, both Opus, both blind. Use `references/rater-prompt.md`.

**Chunk raters.** One agent per screenshot or tight group (one screen, all its states). Inputs: the images, the rubric, the screen's purpose from the inventory, the axe report. They score usability, consistency, beauty, each 1-10, and return JSON findings with location, severity, and a suggested root cause.

**Consistency raters.** One agent per flow, plus one for global chrome (nav, footer, buttons, forms). Inputs: all screenshots of the flow side by side, the rubric. They score cross-screen consistency only.

Three chunk raters per screen in round one, take the median. In later rounds, three raters on changed screens and one on unchanged ones.

Collect every result into `.ui-polish/round-N/findings.json`.

## Phase 4: Triage

You do this, not a subagent:

1. Dedupe findings by location and description.
2. Group by root cause. Forty "padding off by 4px" findings are one token. Say which token.
3. Drop findings that contradict the rubric or a hard constraint.
4. Rank by severity, then by how many screens each fix touches.

After round one only: show the user the ranked list and the median scores before any fixing. Let them cut items. Subjective items (color, copy, layout changes) always need a yes here.

## Phase 5: Fix

Opus fixers, using `references/fixer-prompt.md`. One fixer per root cause group. Each gets: the rubric, the findings in its group, the screenshots, the design system token locations, and an explicit list of files it owns. No two fixers share a file. If they must, run them in sequence or in worktrees and merge yourself.

After all fixers return, run the project's lint, typecheck, and tests. Fix or revert anything red before moving on.

## Phase 6: Verify and loop

1. Re-capture everything with the same names.
2. Pixel-diff against the previous round. Any unexpected change on a screen no fixer touched is a regression. Revert or fix before rating.
3. Rate again with fresh raters (Phase 3).
4. Record medians per dimension per screen in `.ui-polish/scores.md`.

Stop when any of these is true:

- Every required dimension has a median of 10 on every screen in scope, and the user has signed off on beauty if it was not required.
- Medians have not improved for two consecutive rounds. Report the plateau and the remaining findings. Let the user decide.
- `--max-rounds` or `--budget` reached.
- Three or more raters return conflicting findings on the same element in two rounds. That means the rubric is ambiguous. Ask the user to refine it, then continue.

## Reporting

Each round, one short message: median per dimension, number of findings fixed, number remaining, what changed, budget used. Final message: before and after screenshots for the biggest changes, remaining findings, and the diff summary. Ask before committing.

## Anti-patterns

- Telling raters the previous score. They will anchor.
- Telling fixers "get to 10". They will game. Give them the findings.
- Rating isolated chunks only. Inconsistency lives between screens.
- Fixing one screen's padding. Find the shared cause.
- Running the loop on a window the user can see.
