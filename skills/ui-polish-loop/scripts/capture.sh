#!/usr/bin/env bash
# Headless Playwright capture. Never opens a visible window.
#
# One page:
#   capture.sh --url http://localhost:3000/login --out shots/login-desktop.png
#
# A flow (JSON step file, see references/capture.md):
#   capture.sh --steps flows/signup.json --out-dir shots/round-1/signup
#
# Flags:
#   --viewport desktop|mobile|tablet|WxH   (default desktop = 1440x900)
#   --scheme light|dark                    (default light)
#   --scale N                              (device scale factor, default 2)
#   --auth state.json                      (Playwright storageState for logged-in runs)
#   --video                                (record .webm of the flow into --out-dir)
#   --axe                                  (write <name>.axe.json if @axe-core/playwright is installed)
#   --freeze-time ISO                      (default 2026-01-15T10:00:00Z)
#   --no-full-page                         (viewport only)
set -euo pipefail

URL="" STEPS="" OUT="" OUT_DIR="" VIEWPORT="desktop" SCHEME="light" SCALE=2
AUTH="" VIDEO=0 AXE=0 FREEZE="2026-01-15T10:00:00Z" FULL=1

while [[ $# -gt 0 ]]; do
  case "$1" in
    --url) URL="$2"; shift 2 ;;
    --steps) STEPS="$2"; shift 2 ;;
    --out) OUT="$2"; shift 2 ;;
    --out-dir) OUT_DIR="$2"; shift 2 ;;
    --viewport) VIEWPORT="$2"; shift 2 ;;
    --scheme) SCHEME="$2"; shift 2 ;;
    --scale) SCALE="$2"; shift 2 ;;
    --auth) AUTH="$2"; shift 2 ;;
    --video) VIDEO=1; shift ;;
    --axe) AXE=1; shift ;;
    --freeze-time) FREEZE="$2"; shift 2 ;;
    --no-full-page) FULL=0; shift ;;
    -h|--help) sed -n '2,20p' "$0"; exit 0 ;;
    *) echo "unknown flag: $1" >&2; exit 2 ;;
  esac
done

if [[ -z "$URL" && -z "$STEPS" ]]; then echo "need --url or --steps" >&2; exit 2; fi
if [[ -n "$URL" && -z "$OUT" ]]; then echo "--url needs --out" >&2; exit 2; fi
if [[ -n "$STEPS" && -z "$OUT_DIR" ]]; then echo "--steps needs --out-dir" >&2; exit 2; fi

case "$VIEWPORT" in
  desktop) W=1440; H=900 ;;
  tablet)  W=834;  H=1194 ;;
  mobile)  W=390;  H=844 ;;
  *x*)     W="${VIEWPORT%x*}"; H="${VIEWPORT#*x}" ;;
  *) echo "bad --viewport: $VIEWPORT" >&2; exit 2 ;;
esac

# Find a playwright install: local node_modules, then global.
resolve_pw() {
  if node -e "require.resolve('playwright')" 2>/dev/null; then echo ""; return; fi
  local g; g="$(npm root -g 2>/dev/null || true)"
  if [[ -n "$g" && -d "$g/playwright" ]]; then echo "$g"; return; fi
  echo "playwright not found. run: npm i -D playwright && npx playwright install chromium" >&2
  exit 3
}
EXTRA_NODE_PATH="$(resolve_pw)"
export NODE_PATH="${EXTRA_NODE_PATH}${NODE_PATH:+:$NODE_PATH}"

[[ -n "$OUT" ]] && mkdir -p "$(dirname "$OUT")"
[[ -n "$OUT_DIR" ]] && mkdir -p "$OUT_DIR"

export CAP_URL="$URL" CAP_STEPS="$STEPS" CAP_OUT="$OUT" CAP_OUT_DIR="$OUT_DIR"
export CAP_W="$W" CAP_H="$H" CAP_SCHEME="$SCHEME" CAP_SCALE="$SCALE" CAP_AUTH="$AUTH"
export CAP_VIDEO="$VIDEO" CAP_AXE="$AXE" CAP_FREEZE="$FREEZE" CAP_FULL="$FULL"

node - <<'NODE'
const { chromium } = require('playwright');
const fs = require('fs');
const path = require('path');
const e = process.env;

const KILL_MOTION = `
  *, *::before, *::after {
    animation-duration: 0s !important; animation-delay: 0s !important;
    transition-duration: 0s !important; transition-delay: 0s !important;
    caret-color: transparent !important; scroll-behavior: auto !important;
  }`;

(async () => {
  // Bundled chromium first; fall back to an installed Chrome/Edge when the
  // revision is missing so a stale `npx playwright install` does not block a run.
  const launch = async () => {
    try { return await chromium.launch({ headless: true }); }
    catch (err) {
      if (!/Executable doesn't exist/.test(String(err))) throw err;
      for (const channel of ['chrome', 'msedge', 'chromium']) {
        try { const b = await chromium.launch({ headless: true, channel }); console.error(`capture: bundled chromium missing, using ${channel}`); return b; }
        catch {}
      }
      throw new Error('no browser available. run: npx playwright install chromium');
    }
  };
  const browser = await launch();
  const ctxOpts = {
    viewport: { width: +e.CAP_W, height: +e.CAP_H },
    deviceScaleFactor: +e.CAP_SCALE,
    colorScheme: e.CAP_SCHEME,
    reducedMotion: 'reduce',
    locale: 'en-US',
    timezoneId: 'UTC',
  };
  if (e.CAP_AUTH) ctxOpts.storageState = e.CAP_AUTH;
  if (e.CAP_VIDEO === '1') ctxOpts.recordVideo = { dir: e.CAP_OUT_DIR, size: { width: +e.CAP_W, height: +e.CAP_H } };
  const ctx = await browser.newContext(ctxOpts);
  const page = await ctx.newPage();
  await page.clock.install({ time: new Date(e.CAP_FREEZE) });
  await page.addInitScript(() => { Math.random = () => 0.42; });
  await ctx.addInitScript(css => {
    document.addEventListener('DOMContentLoaded', () => {
      const s = document.createElement('style'); s.textContent = css; document.head.appendChild(s);
    });
  }, KILL_MOTION);

  let axe = null;
  if (e.CAP_AXE === '1') {
    try { axe = require('@axe-core/playwright').default; } catch { console.error('axe: @axe-core/playwright not installed, skipping'); }
  }

  const settle = async () => {
    await page.waitForLoadState('networkidle').catch(() => {});
    await page.evaluate(() => document.fonts && document.fonts.ready).catch(() => {});
  };

  const shot = async (file) => {
    await settle();
    await page.screenshot({ path: file, fullPage: e.CAP_FULL === '1', animations: 'disabled' });
    if (axe) {
      const r = await new axe({ page }).analyze();
      fs.writeFileSync(file.replace(/\.png$/, '.axe.json'), JSON.stringify(r.violations, null, 2));
    }
    console.log(file);
  };

  if (e.CAP_URL) {
    await page.goto(e.CAP_URL);
    await shot(e.CAP_OUT);
  } else {
    const steps = JSON.parse(fs.readFileSync(e.CAP_STEPS, 'utf8'));
    const tag = `${e.CAP_W}x${e.CAP_H}-${e.CAP_SCHEME}`;
    for (const s of steps) {
      switch (s.action) {
        case 'goto':   await page.goto(s.url); break;
        case 'click':  await page.locator(s.selector).first().click(); break;
        case 'fill':   await page.locator(s.selector).first().fill(s.value); break;
        case 'select': await page.locator(s.selector).first().selectOption(s.value); break;
        case 'hover':  await page.locator(s.selector).first().hover(); break;
        case 'focus':  await page.locator(s.selector).first().focus(); break;
        case 'press':  await page.keyboard.press(s.key); break;
        case 'scroll': await page.mouse.wheel(0, s.dy ?? 600); break;
        case 'wait':   s.selector ? await page.locator(s.selector).first().waitFor() : await page.waitForTimeout(s.ms ?? 500); break;
        case 'shot':   await shot(path.join(e.CAP_OUT_DIR, `${s.name}-${tag}.png`)); break;
        default: throw new Error(`unknown step action: ${s.action}`);
      }
    }
  }

  await ctx.close();
  await browser.close();
})().catch(err => { console.error(err); process.exit(1); });
NODE
