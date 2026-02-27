#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TASKS_FILE_DEFAULT="$ROOT_DIR/data/real_eval_tasks.jsonl"
HOST_DEFAULT="songsjun@192.168.26.208"
REMOTE_WORKSPACE_DEFAULT="/data/clawdbot/workspace"

HOST="${HOST:-$HOST_DEFAULT}"
REMOTE_WORKSPACE="${REMOTE_WORKSPACE:-$REMOTE_WORKSPACE_DEFAULT}"
TASKS_FILE="${TASKS_FILE:-$TASKS_FILE_DEFAULT}"
RUN_ID="${RUN_ID:-$(date -u +%Y%m%dT%H%M%SZ)}"
THINKING_LEVEL="${THINKING_LEVEL:-minimal}"
TIMEOUT_SECONDS="${TIMEOUT_SECONDS:-180}"

if [[ ! -f "$TASKS_FILE" ]]; then
  echo "Tasks file not found: $TASKS_FILE" >&2
  exit 1
fi

command -v jq >/dev/null || {
  echo "jq is required locally." >&2
  exit 1
}
command -v ssh >/dev/null || {
  echo "ssh is required locally." >&2
  exit 1
}
command -v scp >/dev/null || {
  echo "scp is required locally." >&2
  exit 1
}

REMOTE_EVAL_DIR="$REMOTE_WORKSPACE/memory/meta/eval/$RUN_ID"
REMOTE_TASKS_FILE="$REMOTE_EVAL_DIR/tasks.jsonl"
REMOTE_OUTPUT_JSONL="$REMOTE_EVAL_DIR/records.jsonl"
REMOTE_REPORT_MD="$REMOTE_WORKSPACE/memory/reports/eval_${RUN_ID}.md"

echo "[eval] run_id=$RUN_ID"
echo "[eval] host=$HOST"
echo "[eval] remote_workspace=$REMOTE_WORKSPACE"

ssh "$HOST" "mkdir -p '$REMOTE_EVAL_DIR'"
scp "$TASKS_FILE" "$HOST:$REMOTE_TASKS_FILE"

ssh "$HOST" \
  "RUN_ID='$RUN_ID' REMOTE_WORKSPACE='$REMOTE_WORKSPACE' REMOTE_TASKS_FILE='$REMOTE_TASKS_FILE' REMOTE_OUTPUT_JSONL='$REMOTE_OUTPUT_JSONL' REMOTE_REPORT_MD='$REMOTE_REPORT_MD' THINKING_LEVEL='$THINKING_LEVEL' TIMEOUT_SECONDS='$TIMEOUT_SECONDS' bash -s" <<'EOF'
set -euo pipefail

: "${RUN_ID:?RUN_ID is required}"
: "${REMOTE_WORKSPACE:?REMOTE_WORKSPACE is required}"
: "${REMOTE_TASKS_FILE:?REMOTE_TASKS_FILE is required}"
: "${REMOTE_OUTPUT_JSONL:?REMOTE_OUTPUT_JSONL is required}"
: "${REMOTE_REPORT_MD:?REMOTE_REPORT_MD is required}"
: "${THINKING_LEVEL:?THINKING_LEVEL is required}"
: "${TIMEOUT_SECONDS:?TIMEOUT_SECONDS is required}"

ensure_tools() {
  command -v jq >/dev/null || {
    echo "jq is required on remote host." >&2
    exit 1
  }
  command -v clawdbot >/dev/null || {
    echo "clawdbot is required on remote host." >&2
    exit 1
  }
}

restart_gateway() {
  clawdbot gateway-stop || true
  sleep 1
  nohup clawdbot gateway >/tmp/clawdbot-gateway-eval.log 2>&1 &
  local ok="false"
  for _ in $(seq 1 30); do
    if clawdbot run health >/tmp/clawdbot-health-eval.log 2>&1; then
      ok="true"
      break
    fi
    sleep 2
  done
  if [[ "$ok" != "true" ]]; then
    echo "Gateway did not become healthy after restart." >&2
    tail -n 80 /tmp/clawdbot-gateway-eval.log >&2 || true
    exit 1
  fi
}

seed_group_memory() {
  local root_rel="$1"
  local root_abs="$REMOTE_WORKSPACE/$root_rel"
  rm -rf "$root_abs"
  mkdir -p "$root_abs/short" "$root_abs/mid/programming" "$root_abs/long" "$root_abs/proposals" "$root_abs/meta"

  cat > "$root_abs/short/session_state.md" <<'MEM'
# Session State

updated_at: 2026-02-27T00:00:00.000Z
task: eval seed

## Summary
Seeded evaluation memory facts.
MEM

  cat > "$root_abs/long/rules.md" <<'MEM'
# Eval Facts

- EVAL_FACT_A=AXIS-7429
- EVAL_FACT_B=ORBIT-4402
- EVAL_FACT_C=PATCH-7719
MEM

  cat > "$root_abs/mid/programming/2026-02-20.md" <<'MEM'
## [2026-02-20T09:00:00.000Z] Rank Target Legacy

---
id: "eval_rank_wrong"
title: "Rank Target Legacy"
domain: "programming"
tags: ["rank_target","eval"]
deny_tags: []
created_at: "2026-02-20T09:00:00.000Z"
updated_at: "2026-02-20T09:00:00.000Z"
source:
  type: "eval_seed"
  ref: "seed:wrong"
confidence: 0.20
usage_count: 0
success_count: 0
fail_count: 0
last_used_at: null
ttl_days: 30
layer: "L1"
category: "eval"
---

RANK_TARGET=WRONG-1111
MEM

  cat > "$root_abs/mid/programming/2026-02-27.md" <<'MEM'
## [2026-02-27T09:00:00.000Z] Rank Target Canonical

---
id: "eval_rank_right"
title: "Rank Target Canonical"
domain: "programming"
tags: ["rank_target","eval"]
deny_tags: []
created_at: "2026-02-27T09:00:00.000Z"
updated_at: "2026-02-27T09:00:00.000Z"
source:
  type: "eval_seed"
  ref: "seed:right"
confidence: 0.95
usage_count: 0
success_count: 0
fail_count: 0
last_used_at: null
ttl_days: 30
layer: "L1"
category: "eval"
---

RANK_TARGET=RIGHT-9999
MEM
}

apply_group_config() {
  local group="$1"
  local root_rel="memory/eval/${RUN_ID}/${group}"
  local cfg_json
  cfg_json="$(jq -cn \
    --arg root "$root_rel" \
    '{
      enabled: true,
      config: {
        rootDir: $root,
        retrieve: {
          backend: "bm25",
          topK: 1,
          maxChars: 1200,
          rerank: false,
          includePaths: ["short","mid","long"],
          excludePaths: ["archive","proposals"],
          rgCommand: "rg"
        },
        route: {
          enabled: false,
          fallbackCrossDomainDocs: 0,
          denyTags: ["do_not_recall"]
        },
        writeback: {
          enabled: true,
          sessionStateFile: "short/session_state.md",
          midDir: "mid",
          maxEntryChars: 1200,
          qualityGate: "basic",
          proposalsEnabled: false
        },
        maintenance: {
          enabled: false,
          intervalMinutes: 1440,
          archiveAfterDays: 7,
          dedupe: true,
          weeklyEnabled: true,
          weeklyWeekday: 1
        },
        lifecycle: {
          enabled: false,
          promoteThreshold: 0.75,
          archiveThreshold: 0.35,
          archiveInactiveDays: 30
        },
        debug: false
      }
    }')"

  case "$group" in
    G0)
      cfg_json="$(jq -cn \
        --arg root "$root_rel" \
        '{
          enabled: true,
          config: {
            rootDir: $root,
            retrieve: {
              backend: "bm25",
              topK: 1,
              maxChars: 1200,
              rerank: false,
              includePaths: ["_disabled"],
              excludePaths: ["archive","proposals"],
              rgCommand: "rg"
            },
            route: {
              enabled: false,
              fallbackCrossDomainDocs: 0,
              denyTags: ["do_not_recall"]
            },
            writeback: {
              enabled: false,
              sessionStateFile: "short/session_state.md",
              midDir: "mid",
              maxEntryChars: 1200,
              qualityGate: "basic",
              proposalsEnabled: false
            },
            maintenance: {
              enabled: false,
              intervalMinutes: 1440,
              archiveAfterDays: 7,
              dedupe: true,
              weeklyEnabled: true,
              weeklyWeekday: 1
            },
            lifecycle: {
              enabled: false,
              promoteThreshold: 0.75,
              archiveThreshold: 0.35,
              archiveInactiveDays: 30
            },
            debug: false
          }
        }')"
      ;;
    G1)
      # time-layer only baseline with memory read/write but no route/rerank/lifecycle
      ;;
    G2)
      cfg_json="$(jq '.config.route.enabled = true' <<<"$cfg_json")"
      ;;
    G3)
      cfg_json="$(jq '.config.route.enabled = true
        | .config.retrieve.rerank = true
        | .config.lifecycle.enabled = true
        | .config.writeback.qualityGate = "strict"
        | .config.writeback.proposalsEnabled = true' <<<"$cfg_json")"
      ;;
    *)
      echo "Unknown group: $group" >&2
      exit 1
      ;;
  esac

  clawdbot run config set "plugins.slots.memory" "memory-md-index"
  clawdbot run config set "plugins.entries.memory-md-index" "$cfg_json"

  seed_group_memory "$root_rel"
  restart_gateway
}

json_escape() {
  jq -Rn --arg v "$1" '$v'
}

count_usage() {
  local usage_file="$1"
  local session_id="$2"
  local event_type="$3"
  if [[ ! -f "$usage_file" ]]; then
    echo "0"
    return
  fi
  jq -Rs --arg sid "$session_id" --arg typ "$event_type" '
    split("\n")
    | map(select(length > 0) | (fromjson? // empty))
    | map(select(.sessionId == $sid and .type == $typ))
    | length
  ' "$usage_file"
}

bool_to_json() {
  if [[ "$1" == "true" ]]; then
    echo "true"
  else
    echo "false"
  fi
}

run_group() {
  local group="$1"
  local root_rel="memory/eval/${RUN_ID}/${group}"
  local usage_file="$REMOTE_WORKSPACE/$root_rel/meta/usage.jsonl"
  local group_records="$REMOTE_WORKSPACE/memory/meta/eval/${RUN_ID}/${group}.jsonl"
  : > "$group_records"

  echo "[eval][${group}] apply config"
  apply_group_config "$group"
  echo "[eval][${group}] running tasks"

  while IFS= read -r task_line; do
    [[ -z "$task_line" ]] && continue
    local task_id task_prompt expected_regex session_id task_out response_text
    local duration_ms input_tokens output_tokens recall_total injected_count useful_citations
    local irrelevant_recall success_json first_turn_json long_polluted_json

    task_id="$(jq -r '.id' <<<"$task_line")"
    task_prompt="$(jq -r '.prompt' <<<"$task_line")"
    expected_regex="$(jq -r '.expected_regex' <<<"$task_line")"
    session_id="eval-${RUN_ID}-${group}-${task_id}"

    local err_file
    err_file="$(mktemp)"
    task_out="$(clawdbot run agent --session-id "$session_id" --message "$task_prompt" --thinking "$THINKING_LEVEL" --timeout "$TIMEOUT_SECONDS" --json 2>"$err_file")"
    if rg -q "falling back to embedded|gateway closed" "$err_file"; then
      echo "[eval][${group}] gateway fallback detected for ${task_id}, aborting run." >&2
      cat "$err_file" >&2
      rm -f "$err_file"
      exit 1
    fi
    rm -f "$err_file"

    response_text="$(jq -r '.result.payloads[0].text // ""' <<<"$task_out")"
    duration_ms="$(jq -r '.result.meta.durationMs // 0' <<<"$task_out")"
    input_tokens="$(jq -r '.result.meta.agentMeta.usage.input // 0' <<<"$task_out")"
    output_tokens="$(jq -r '.result.meta.agentMeta.usage.output // 0' <<<"$task_out")"

    if printf '%s\n' "$response_text" | rg -q "$expected_regex"; then
      success_json="true"
      first_turn_json="true"
    else
      success_json="false"
      first_turn_json="false"
    fi

    recall_total="$(count_usage "$usage_file" "$session_id" "retrieve_hit")"
    injected_count="$(count_usage "$usage_file" "$session_id" "prompt_injected")"
    if [[ "$success_json" == "true" ]]; then
      useful_citations="$injected_count"
    else
      useful_citations="0"
    fi
    irrelevant_recall="$((recall_total - useful_citations))"
    if (( irrelevant_recall < 0 )); then
      irrelevant_recall=0
    fi

    long_polluted_json="false"

    jq -c -n \
      --arg taskId "$task_id" \
      --arg group "$group" \
      --argjson success "$(bool_to_json "$success_json")" \
      --argjson firstTurn "$(bool_to_json "$first_turn_json")" \
      --argjson inputTokens "${input_tokens:-0}" \
      --argjson outputTokens "${output_tokens:-0}" \
      --argjson latencyMs "${duration_ms:-0}" \
      --argjson injectedCount "${injected_count:-0}" \
      --argjson usefulCitations "${useful_citations:-0}" \
      --argjson recallTotal "${recall_total:-0}" \
      --argjson irrelevantRecall "${irrelevant_recall:-0}" \
      --argjson longPolluted "$(bool_to_json "$long_polluted_json")" \
      '{
        taskId: $taskId,
        group: $group,
        success: $success,
        firstTurn: $firstTurn,
        inputTokens: $inputTokens,
        outputTokens: $outputTokens,
        latencyMs: $latencyMs,
        injectedCount: $injectedCount,
        usefulCitations: $usefulCitations,
        recallTotal: $recallTotal,
        irrelevantRecall: $irrelevantRecall,
        longPolluted: $longPolluted
      }' >> "$group_records"

    echo "[eval][${group}] ${task_id} success=${success_json} latencyMs=${duration_ms:-0} input=${input_tokens:-0} output=${output_tokens:-0}"
  done < "$REMOTE_TASKS_FILE"

  cat "$group_records" >> "$REMOTE_OUTPUT_JSONL"
}

ensure_tools
: > "$REMOTE_OUTPUT_JSONL"

for group in G0 G1 G2 G3; do
  run_group "$group"
done

echo "[eval] generating report"
clawdbot run memory-md-index evaluate --input "/workspace/memory/meta/eval/${RUN_ID}/records.jsonl" --output "/workspace/memory/reports/eval_${RUN_ID}.md"

echo "[eval] done"
echo "records_jsonl=$REMOTE_OUTPUT_JSONL"
echo "report_md=$REMOTE_REPORT_MD"
sed -n '1,30p' "$REMOTE_REPORT_MD"
EOF

LOCAL_OUT_DIR="$ROOT_DIR/reports/eval_runs/$RUN_ID"
mkdir -p "$LOCAL_OUT_DIR"
scp "$HOST:$REMOTE_OUTPUT_JSONL" "$LOCAL_OUT_DIR/records.jsonl"
scp "$HOST:$REMOTE_REPORT_MD" "$LOCAL_OUT_DIR/report.md"

echo "[eval] local artifacts:"
echo "  - $LOCAL_OUT_DIR/records.jsonl"
echo "  - $LOCAL_OUT_DIR/report.md"
