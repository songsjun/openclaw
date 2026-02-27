# Step 6 Report: Daily/Weekly Maintenance and Reporting

## Goal

Complete maintenance workflow with scheduled daily hygiene and weekly consolidation:

1. Daily pass: archive + dedupe + lifecycle candidates.
2. Weekly pass: rule consolidation + conflict report.
3. Produce auditable daily/weekly report artifacts.

## Implemented Changes

1. Config/schema updates

- Added maintenance config:
  - `maintenance.weeklyEnabled`
  - `maintenance.weeklyWeekday` (0-6, UTC weekday)

2. Store layout update

- Added `memory/reports/` directory in layout bootstrap.

3. Maintenance engine (`maintenance.ts`)

- Added maintenance mode support: `auto|daily|weekly`.
- Daily report generation: `memory/reports/daily_YYYY-MM-DD.md`.
- Weekly consolidation:
  - reads `memory/proposals/rules_*.md`,
  - dedupes candidate rules,
  - detects simple conflicts (`always/never`, `enable/disable`),
  - writes weekly report and consolidated proposal:
    - `memory/reports/weekly_YYYY-MM-DD.md`
    - `memory/proposals/rules_consolidated_YYYY-MM-DD.md`
- Auto mode weekly scheduling state persisted in:
  - `memory/meta/maintenance_state.json` (once per ISO week).

4. CLI/runtime integration (`index.ts`)

- `memory-md-index maintain --mode auto|daily|weekly`.
- Service timer uses `auto` mode to run daily + weekly according to policy.

5. Tests

- Updated maintenance tests for:
  - daily pass + report output,
  - weekly consolidation + conflict report output.
- Updated config/store tests for new fields/layout.

## Validation Commands

```bash
pnpm exec oxfmt --check extensions/memory-md-index/*.ts
pnpm exec vitest run --config vitest.config.ts extensions/memory-md-index/*.test.ts
```

## Validation Result

- Format: passed.
- Tests: `10` files passed, `37` tests passed, `0` failed.

## Step 6 Acceptance Check

1. `daily` 维护产物完整（去重/归档/日报）：通过。
2. `weekly` 规则提纯与冲突报告可生成：通过。
3. 自动模式可按周节奏触发 weekly：通过。

Status: `PASSED`
