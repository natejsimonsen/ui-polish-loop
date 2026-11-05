# Capture reference

`scripts/capture.sh` is the only approved way to take screenshots in this loop. It is always headless.

## Setup, once per project

```bash
npm i -D playwright @axe-core/playwright
npx playwright install chromium
```

Logged-in flows: save auth state once, headless, then reuse it.

```bash
node -e "
const {chromium}=require('playwright');(async()=>{
const b=await chromium.launch({headless:true});const c=await b.newContext();const p=await c.newPage();
await p.goto('http://localhost:3000/login');
await p.fill('[name=email]','test@example.com');await p.fill('[name=password]','pass');
await p.click('button[type=submit]');await p.waitForURL('**/dashboard');
await c.storageState({path:'.ui-polish/auth.json'});await b.close();})()"
```

Run the script from a directory where `playwright` resolves (the app's package root), or point `NODE_PATH` at a `node_modules` that has it. If the bundled Chromium revision is missing, the script falls back to an installed Chrome or Edge, still headless, and says so on stderr.

## One page

```bash
scripts/capture.sh --url http://localhost:3000/settings \
  --out .ui-polish/round-1/settings/settings-default-desktop.png \
  --viewport desktop --auth .ui-polish/auth.json --axe
```

Run it again with `--viewport mobile` and `--scheme dark` as needed. Keep the file name pattern `<screen>-<state>-<viewport>.png` so rounds diff cleanly.

## A flow

Step file, one JSON array:

```json
[
  { "action": "goto",  "url": "http://localhost:3000/signup" },
  { "action": "shot",  "name": "signup-empty" },
  { "action": "focus", "selector": "[name=email]" },
  { "action": "shot",  "name": "signup-email-focus" },
  { "action": "fill",  "selector": "[name=email]", "value": "not-an-email" },
  { "action": "click", "selector": "button[type=submit]" },
  { "action": "wait",  "selector": "[role=alert]" },
  { "action": "shot",  "name": "signup-validation-error" },
  { "action": "hover", "selector": "a[href='/login']" },
  { "action": "shot",  "name": "signup-login-link-hover" }
]
```

Actions: `goto`, `click`, `fill`, `select`, `hover`, `focus`, `press` (key), `scroll` (dy), `wait` (selector or ms), `shot` (name).

```bash
scripts/capture.sh --steps .ui-polish/flows/signup.json \
  --out-dir .ui-polish/round-1/signup --viewport mobile --video --axe
```

`shot` names get `-<WxH>-<scheme>` appended. `--video` writes a `.webm` into the out dir for transition review.

## What the script forces

- `headless: true`, no exceptions.
- Clock frozen at `--freeze-time` so timestamps and relative dates match across rounds.
- `Math.random` pinned so randomized content is stable.
- All CSS animations and transitions set to zero duration, caret hidden.
- `prefers-reduced-motion: reduce`, locale `en-US`, timezone UTC.
- Waits for network idle and web fonts before each shot.

## Pixel diff between rounds

```bash
npx odiff .ui-polish/round-1/settings/settings-default-desktop.png \
          .ui-polish/round-2/settings/settings-default-desktop.png \
          .ui-polish/round-2/settings/settings-default-desktop.diff.png --threshold 0.05
```

Exit code 22 means pixels differ. Any diff on a screen no fixer touched is a regression.

## Seed data

Empty, loading, and long-content states need data. Write a seed command into `.ui-polish/setup.md` and run it before every round. For loading states, add a `wait` step with a short `ms` right after `goto`, or throttle with a route handler in a custom step file. Do not screenshot a spinner that depends on network speed and call it reproducible.
