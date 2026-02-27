# Step 3 Report: Retrieval Rerank and Prompt Budget Control

## Goal

Enhance retrieval quality after backend search by introducing deterministic rerank:

1. Keep lexical retrieval as primary signal.
2. Add recency, usage, and confidence signals.
3. Preserve low-risk rollback via config switch.

## Implemented Changes

1. Added `rerank.ts`

- Final score formula:
  - `0.65 * lexical`
  - `0.15 * recency`
  - `0.10 * usage`
  - `0.10 * confidence`
- Returns reranked hits plus explainable component details.

2. Integrated in `index.ts`

- `before_prompt_build` now:
  - retrieves raw hits,
  - optionally reranks (`retrieve.rerank=true`),
  - truncates to `topK`,
  - injects within `maxChars`.
- Debug mode logs top rerank components.

3. Config/schema updates

- Added `retrieve.rerank` (default `true`) in parser and plugin schema.

4. Tests

- Added `rerank.test.ts` (tie-breaking by recency/confidence and metadata-missing fallback).
- Updated config/indexer tests for new config key.

## Validation Commands

```bash
pnpm exec oxfmt --check extensions/memory-md-index/*.ts
pnpm exec vitest run --config vitest.config.ts extensions/memory-md-index/*.test.ts
```

## Validation Result

- Format: passed.
- Tests: `9` files passed, `27` tests passed, `0` failed.

## Step 3 Acceptance Check

1. 重排链路可开关：通过（`retrieve.rerank`）。
2. 注入预算仍受 `topK/maxChars` 控制：通过。
3. 重排结果可解释（debug 分量日志）：通过。

Status: `PASSED`
