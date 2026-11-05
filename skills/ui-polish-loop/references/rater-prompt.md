# Rater prompt templates

Model: opus. Raters are blind. Never include prior scores, prior findings, round number, or the diff.

## Chunk rater

```
You are rating one screen of a web app against a written rubric. Score only what you see. Do not guess at screens you were not shown.

Rubric:
<paste .ui-polish/rubric.md>

Screen: <name>
Purpose: <one sentence from inventory.md>
Flow position: <"step 2 of 4 in signup">
Viewport: <desktop 1440x900 | mobile 390x844>
Images attached: <list of file paths; read each with the Read tool>
Axe report: <path or "none">

Inspect padding, margins, alignment, type scale, color roles, radii, hover and focus treatments, contrast, touch target size, copy clarity, and empty, loading, and error states if shown. Measure, do not eyeball: if two gaps look different, say which is larger and estimate by how much.

Return only JSON:
{
  "screen": "<name>",
  "scores": { "usability": 1-10, "consistency": 1-10, "beauty": 1-10 },
  "findings": [
    {
      "id": "short-slug",
      "severity": "blocker | major | minor | nit",
      "dimension": "usability | consistency | beauty",
      "location": "what element, where on the screen",
      "observed": "what is wrong, with measurements where possible",
      "expected": "what the rubric says it should be",
      "likely_root_cause": "a shared token, component, or a one-off override; name it if you can"
    }
  ],
  "what_is_already_at_10": ["..."]
}

A 10 means you found nothing. If you give a 10 and list findings, you are wrong about one of them.
```

## Consistency rater

```
You are checking consistency across several screens of one flow. You are not rating individual screens.

Rubric:
<paste .ui-polish/rubric.md>

Flow: <name>
Screens in order: <list with purposes>
Images attached: <paths, in flow order; read each>

Compare across screens: spacing scale, type scale, button and input styles, radii, color roles, icon size and weight, header and nav placement, empty and error state patterns, copy tone. Anything that differs between two screens for no stated reason is a finding.

Return only JSON:
{
  "flow": "<name>",
  "consistency": 1-10,
  "findings": [
    {
      "id": "short-slug",
      "severity": "blocker | major | minor | nit",
      "screens": ["a", "b"],
      "observed": "screen a uses X, screen b uses Y",
      "expected": "...",
      "likely_root_cause": "..."
    }
  ]
}
```

## Global chrome rater

Same as the consistency rater, but given one screenshot from every flow and told to check only nav, footer, page headers, primary buttons, form controls, and toasts.

## Aggregation

For each screen take the median of three chunk raters per dimension. Keep every finding that two or more raters reported, or that one reported as blocker or major. Drop single-rater nits unless they name a root cause already in the list.
