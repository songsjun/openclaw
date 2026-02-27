# Memory B++ Release Notes (Draft)

Date: 2026-02-27  
Scope: `extensions/memory-md-index` + `projects/memory-bpp-plan/*`

## Decision

- Formal gate decision after real 208 G0/G1/G2/G3 run: `NO_GO`
- Blocking rule:
  - `g2_success_vs_g0` failed (`-20.00%`, required `>= 8.00%`)

## Modules Included

1. Memory plugin module (`extensions/memory-md-index`)
   - Prompt injection hook: retrieve + bounded context injection.
   - Post-run writeback hook: `session_state` + structured mid entries.
   - Route filter, rerank, lifecycle scoring and promotion/archive.
   - Daily/weekly maintenance commands and evaluation command.
2. Evaluation engineering module (`projects/memory-bpp-plan/data` + `scripts`)
   - Real task set JSONL for control runs.
   - Remote 208 execution script:
     - per-group config mutation (G0/G1/G2/G3),
     - seeded conflict corpus,
     - auto-collect evaluate input JSONL,
     - auto-generate markdown gate report.
3. Validation evidence module (`projects/memory-bpp-plan/reports/eval_runs`)
   - Archived real run outputs and reports for:
     - `real_20260227_4`
     - `real_20260227_5`

## Risk and Rollout

1. Keep `memory-core` disabled; continue running `memory-md-index` only in controlled mode.
2. Do not promote to production defaults until gate turns `GO`.
3. Next release candidate must show:
   - `G2 vs G0 success delta >= 8%`,
   - `G3 vs G2 success delta >= 3%`,
   - token/latency growth within configured limits.

## Verification Snapshot

1. Plugin unit tests:
   - `corepack pnpm vitest run extensions/memory-md-index/*.test.ts`
   - result: `11 files, 39 tests, 0 failed`
2. Script syntax:
   - `bash -n projects/memory-bpp-plan/scripts/run_real_eval_208.sh`
   - result: `pass`
