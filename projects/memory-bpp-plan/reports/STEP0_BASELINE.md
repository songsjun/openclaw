# Step 0 Baseline Report

## Scope

Baseline freeze for `extensions/memory-md-index` before Step 1 data-model changes.

## Baseline Date

- 2026-02-27

## Commands Executed

```bash
pnpm exec vitest run --config vitest.config.ts extensions/memory-md-index/*.test.ts
pnpm exec oxfmt --check extensions/memory-md-index/*.ts
```

## Results

- Vitest: `7` files passed, `20` tests passed, `0` failed.
- Format check: passed (`14` files checked).

## Baseline Acceptance

1. Plugin test suite is green.
2. Formatting is green.
3. Baseline metrics are captured as comparison reference for Step 1+.

Status: `PASSED`
