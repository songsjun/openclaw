# Step 8 Report: Remote 208 Deployment and Runtime Validation

## Date

- 2026-02-27

## Target

- Host: `songsjun@192.168.26.208`
- Runtime workspace: `/data/clawdbot/workspace`
- Plugin path: `/data/clawdbot/workspace/extensions/memory-md-index`

## Actions Executed

1. Synced plugin files to 208:

```bash
rsync -az --delete extensions/memory-md-index/ songsjun@192.168.26.208:/data/clawdbot/workspace/extensions/memory-md-index/
```

2. Verified plugin slot + allowlist configuration remained correct.
3. Restarted gateway.
4. Verified plugin load state:
   - `memory-md-index` loaded
   - `memory-core` disabled
5. Runtime command checks:
   - `memory-md-index maintain --mode daily`
   - `memory-md-index maintain --mode weekly`
   - `memory-md-index maintain --mode auto`
   - `memory-md-index evaluate --input ... --output ...`

## Validation Results

1. Daily mode produced:
   - `memory/reports/daily_2026-02-27.md`
2. Weekly mode produced:
   - `memory/reports/weekly_2026-02-27.md`
   - `memory/proposals/rules_consolidated_2026-02-27.md`
3. Auto mode on 2026-02-27 did not run weekly (expected by weekday policy):
   - `weeklyConsolidatedRules=0`
   - `weeklyConflictPairs=0`
4. Evaluate command generated:
   - `memory/reports/eval_sample.md`
   - gate result: `NO_GO` (sample data intentionally did not satisfy `G3 vs G2 success >= 3%`)

## Real Control Run (2026-02-27, run_id=real_20260227_5)

1. Ran full G0/G1/G2/G3 on 208 via:
   - `projects/memory-bpp-plan/scripts/run_real_eval_208.sh`
2. Auto-generated evaluate input JSONL:
   - remote: `/data/clawdbot/workspace/memory/meta/eval/real_20260227_5/records.jsonl`
   - local copy: `projects/memory-bpp-plan/reports/eval_runs/real_20260227_5/records.jsonl`
3. Generated formal report:
   - remote: `/data/clawdbot/workspace/memory/reports/eval_real_20260227_5.md`
   - local copy: `projects/memory-bpp-plan/reports/eval_runs/real_20260227_5/report.md`
4. Gate result:
   - `NO_GO`
5. Key metrics:
   - `G0 success=100.00%`
   - `G1 success=80.00%`
   - `G2 success=80.00%`
   - `G3 success=100.00%`
   - `G2 vs G0 success delta=-20.00%` (required `>= 8.00%`, **failed**)
   - `G2 vs G0 input token growth=-22.66%` (pass)
   - `G2 vs G0 p95 latency growth=-34.36%` (pass)

## Notes

1. `clawdbot` consistently emits unrelated doctor warnings on each run (state-dir migration and channel key migration). These did not block plugin execution.
2. For `evaluate`, input/output paths must use container-visible `/workspace/...` when invoking via `clawdbot run`.
3. In this run, `G3` recovered `rank_target`, but gate still failed because `G2` did not outperform `G0`.

Status: `PASSED (validation executed, decision NO_GO)`
