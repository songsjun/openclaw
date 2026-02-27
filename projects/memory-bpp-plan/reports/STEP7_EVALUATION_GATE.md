# Step 7 Report: A/B Evaluation and Go/No-Go Gate

## Goal

Provide executable evaluation flow for G0/G1/G2/G3 and gate decision:

1. Aggregate per-group metrics.
2. Compute required deltas and confidence intervals.
3. Emit deterministic GO/NO_GO decision with check list.

## Implemented Changes

1. Added `evaluation.ts`

- JSONL input parser for evaluation records.
- Group metrics aggregation:
  - success rate
  - first-turn rate
  - useful citation rate
  - irrelevant recall rate
  - avg input/output tokens
  - p95 latency
  - long pollution rate
- Bootstrap 95% confidence interval for success deltas.
- Gate checks implemented from plan:
  - `G2 vs G0` success >= 8%
  - `G2 vs G0` irrelevant recall increase <= 2%
  - `G3 vs G2` success >= 3%
  - `G3 vs G2` long pollution increase <= 0
  - token growth <= 20%
  - p95 latency growth <= 15%
- Markdown report renderer + file output helper.

2. CLI integration (`index.ts`)

- Added command:
  - `memory-md-index evaluate --input <jsonl> [--output <md>]`
- Output defaults to:
  - `memory/reports/evaluation_YYYY-MM-DD.md`

3. Tests

- Added `evaluation.test.ts`:
  - GO case (all gate checks pass)
  - NO_GO case (multiple checks fail + report write verification)

## Validation Commands

```bash
pnpm exec oxfmt --check extensions/memory-md-index/*.ts
pnpm exec vitest run --config vitest.config.ts extensions/memory-md-index/*.test.ts
```

## Validation Result

- Format: passed.
- Tests: `11` files passed, `39` tests passed, `0` failed.

## Step 7 Acceptance Check

1. G0/G1/G2/G3 指标可聚合并输出对比：通过。
2. 95% 置信区间与门禁规则可计算：通过。
3. 可产出 `GO/NO_GO` 报告供上线决策：通过。

Status: `PASSED`
