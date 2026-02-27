# Step 5 Report: Usage Events and Lifecycle Scoring

## Goal

Close the reinforcement loop with measurable signals:

1. Record usage and outcome events (append-only).
2. Compute lifecycle score with success/fail binding.
3. Emit promotion/archive candidates for review and maintenance.

## Implemented Changes

1. Config/schema updates

- Added `lifecycle` section:
  - `enabled`
  - `promoteThreshold`
  - `archiveThreshold`
  - `archiveInactiveDays`

2. Added `lifecycle.ts`

- `appendUsageEvent()` / `readUsageEvents()`
- `evaluateLifecycleDecisions()` using:
  - success rate
  - usage frequency
  - recency
  - confidence
  - fail penalty
- `appendLifecycleDecisions()` to `memory/meta/lifecycle.jsonl`

3. Hook integration (`index.ts`)

- `before_prompt_build` logs:
  - `retrieve_hit`
  - `prompt_injected`
- `agent_end` logs:
  - `task_outcome` bound to injected memory IDs (success/fail)

4. Maintenance integration (`maintenance.ts`)

- Reads usage events and evaluates lifecycle decisions.
- Emits candidate counts (`promoteCandidates`, `archiveCandidates`) in result/logs.

5. Tests

- Added `lifecycle.test.ts`.
- Extended config and typed config tests for lifecycle fields.

## Validation Commands

```bash
pnpm exec oxfmt --check extensions/memory-md-index/*.ts
pnpm exec vitest run --config vitest.config.ts extensions/memory-md-index/*.test.ts
```

## Validation Result

- Format: passed.
- Tests: `10` files passed, `35` tests passed, `0` failed.

## Step 5 Acceptance Check

1. usage 事件日志写入并可读取：通过。
2. 强化/淘汰评分绑定 success/fail 信号：通过。
3. 维护任务可输出 promote/archive 候选：通过。

Status: `PASSED`
