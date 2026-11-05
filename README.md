# ui-polish-loop

A Claude Code skill that polishes a web app's UI in a loop. It screenshots
every screen and state headless, has blind raters score them against a rubric
you write, sends fixers after the root causes, then re-rates with fresh raters.
It stops when the rubric is met, the scores stop improving, or the budget runs
out.

It is expensive. A full run can use 150 subagent calls. It never runs on its
own; you start it with `/ui-polish-loop`.

## Install

As a plugin, in a Claude Code session:

```
/plugin install ui-polish-loop --marketplace natejsimonsen/ui-polish-loop
```

Answer `y` to add the marketplace, then pick the user scope.

Or from a shell, in one line:

```
claude plugin marketplace add natejsimonsen/ui-polish-loop && claude plugin install ui-polish-loop@ui-polish-loop
```

Or as a plain skill:

```
git clone https://github.com/natejsimonsen/ui-polish-loop /tmp/ui-polish-loop
cp -R /tmp/ui-polish-loop/skills/ui-polish-loop ~/.claude/skills/
```

The capture script needs Playwright in the app you are polishing:

```
npm i -D playwright @axe-core/playwright
npx playwright install chromium
```

## Use

```
/ui-polish-loop [app-dir|url] [--scope flow,flow] [--max-rounds N] [--viewports desktop,mobile] [--budget N]
```

1. It asks about your design goals and writes `.ui-polish/rubric.md`.
2. It lists every screen and state and shows you the list.
3. It captures, rates, and shows you the ranked findings before fixing.
4. It loops until done and asks before committing anything.

All output goes in `.ui-polish/` in your project.

## Run from a checkout

```
claude --plugin-dir /path/to/ui-polish-loop
```

## License

MIT
