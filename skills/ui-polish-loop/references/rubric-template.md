# Rubric: <app name>

Written from the user's answers in Phase 0. Every rater and fixer receives this file verbatim.

## Philosophy

<one or two sentences, e.g. "Minimal and clean. Generous whitespace, one accent color, no decoration without function.">

Reference apps: <Linear, Stripe dashboard, ...>

## Hard constraints

- <must keep brand colors #xxxxxx and #yyyyyy>
- <no layout changes to the checkout page>
- <use design system tokens in `path/to/tokens`; no raw px or hex values>

## Required dimensions

| Dimension   | Must reach 10 | Notes                                  |
| ----------- | ------------- | -------------------------------------- |
| Usability   | yes           |                                        |
| Consistency | yes           |                                        |
| Beauty      | no            | human sign-off at the end of each round |

## What each score means

**Usability**
- 10: Every action's purpose is obvious before clicking. Focus order matches visual order. All text passes WCAG AA contrast. Touch targets are at least 44px on mobile. Errors say what to do next. No axe violations.
- 7: Works, but one or two actions need a second look, or a focus ring is missing somewhere.
- 4: Primary action is unclear, or an error state gives no recovery path.
- 1: Cannot complete the flow.

**Consistency**
- 10: Same spacing scale, type scale, radii, and color roles everywhere. Same component for the same job on every screen. Identical hover, focus, and disabled treatments. Alignment to a grid with no one-off offsets.
- 7: One deviation visible on the screen, such as a button with a different radius.
- 4: Multiple components doing the same job look different, or spacing changes from screen to screen.
- 1: No visible system.

**Beauty** (against the stated philosophy)
- 10: Nothing to add and nothing to remove. Hierarchy reads at a glance. Matches the reference apps' quality.
- 7: Good, with visual noise or a weak hierarchy in one area.
- 4: Cluttered or flat. Hierarchy unclear.
- 1: Unstyled.

## Spacing and type scale

<fill from the design system, e.g. spacing 4/8/12/16/24/32/48; type 12/14/16/20/24/32; radius 4/8/12>
