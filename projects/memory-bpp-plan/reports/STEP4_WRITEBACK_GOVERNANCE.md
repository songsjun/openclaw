# Step 4 Report: Writeback Governance and Proposal Flow

## Goal

Reduce writeback pollution and keep long-term rule evolution safe:

1. Add writeback quality gate (`off/basic/strict`).
2. Keep `long/skills` immutable by default.
3. Extract rule candidates into proposal files for review.

## Implemented Changes

1. Config updates (`config.ts`, `openclaw.plugin.json`)

- Added `writeback.qualityGate`.
- Added `writeback.proposalsEnabled`.

2. Store updates (`store.ts`)

- Added `appendProposal()` to write candidate artifacts under `memory/proposals/`.

3. Writeback updates (`writeback.ts`)

- Added `extractRuleCandidates()`.
- Added `passesQualityGate()` with strict mode.
- Mid-memory append now gated by quality policy.
- Rule candidates are written to `memory/proposals/rules_YYYY-MM-DD.md` when enabled.

4. Tests

- `store.test.ts`: proposal append coverage.
- `writeback.test.ts`: proposal generation + strict gate behavior.
- `config.test.ts`: new writeback config defaults/overrides/validation.

## Validation Commands

```bash
pnpm exec oxfmt --check extensions/memory-md-index/*.ts
pnpm exec vitest run --config vitest.config.ts extensions/memory-md-index/*.test.ts
```

## Validation Result

- Format: passed.
- Tests: `9` files passed, `32` tests passed, `0` failed.

## Step 4 Acceptance Check

1. 写回质量门控可配置且生效：通过。
2. 规则提案输出到 proposals，不自动写 long/skills：通过。
3. 写回稳定性无回归：通过。

Status: `PASSED`
