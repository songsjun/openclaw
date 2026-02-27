# 评测方案（Memory B++）

## 1. 评测目标

1. 验证记忆增强是否显著提升任务成功率。
2. 分离验证三项能力贡献：时间分层、分类标签、强化淘汰。
3. 量化成本与副作用：token、延迟、误召回、污染率。

## 2. 实验设计

## 2.1 对照组

1. `G0` 基线：memory 插件关闭。
2. `G1` 时间分层：short/mid/long，仅时间维度。
3. `G2` 时间 + 分类：加入 domain/tags 与路由 hints。
4. `G3` 时间 + 分类 + 强化淘汰：全量策略。

约束：

1. 同一模型、同一温度、同一工具权限、同一超时。
2. 每组至少跑 120 条样本，顺序随机化，避免批次偏差。

## 2.2 样本集

目标样本数：120（首轮可扩展到 300）

分布建议：

1. 编程/工具：50
2. 运维/环境：30
3. 产品/流程：20
4. 歧义与跨域：20

每条样本字段：

```yaml
id: T001
query: "为什么 gateway 在 node 20 上报错"
domain: programming
context: "OpenClaw local run on macOS"
must_include:
  - "Node 22+"
must_avoid:
  - "无关人名记录"
expected_tools:
  - "shell"
expected_outcome: "给出可执行修复命令和版本说明"
```

## 3. 指标定义

## 3.1 主指标

1. 任务成功率（Task Success Rate）

- 定义：一次交互内达到 `expected_outcome` 的比例。

2. 首轮解决率（First-Turn Resolution）

- 定义：无需用户追问即可满足目标的比例。

## 3.2 质量指标

1. 有效引用率（Useful Memory Citation Rate）

- 定义：注入记忆中被最终回答实际使用的比例。

2. 误召回率（Irrelevant Recall Rate）

- 定义：进入 prompt 但被判定无关/错误的记忆比例。

3. 冲突触发率（Conflict Trigger Rate）

- 定义：单次检索中出现互相冲突记忆的比例。

## 3.3 成本指标

1. 平均输入 token。
2. 平均输出 token。
3. P95 延迟。
4. 维护任务耗时（daily/weekly）。

## 3.4 治理指标

1. 重复率（duplicate ratio）。
2. 归档率（archive ratio）。
3. long 层污染率（进入 long 后被撤回或标错的比例）。
4. 记忆净增长率（每周净新增可用记忆）。

## 4. 埋点与日志 schema

日志统一写 `jsonl`，按日分文件：
`memory/meta/metrics/YYYY-MM-DD/*.jsonl`

## 4.1 retrieve 事件

```json
{
  "ts": "2026-02-27T10:00:01Z",
  "type": "retrieve",
  "task_id": "T001",
  "group": "G2",
  "query": "why gateway fails on node 20",
  "domain_hint": "programming",
  "backend": "rg",
  "candidate_count": 42,
  "topk_ids": ["mem_a", "mem_b"],
  "latency_ms": 33
}
```

## 4.2 inject 事件

```json
{
  "ts": "2026-02-27T10:00:02Z",
  "type": "inject",
  "task_id": "T001",
  "injected_ids": ["mem_a", "mem_b"],
  "chars": 1780,
  "truncated": false
}
```

## 4.3 outcome 事件

```json
{
  "ts": "2026-02-27T10:00:20Z",
  "type": "outcome",
  "task_id": "T001",
  "success": true,
  "first_turn": true,
  "user_correction": false,
  "failure_reason": null
}
```

## 4.4 lifecycle 事件

```json
{
  "ts": "2026-02-28T01:00:00Z",
  "type": "lifecycle",
  "memory_id": "mem_a",
  "score": 0.79,
  "decision": "promote_candidate",
  "reason": "high_success_and_usage"
}
```

## 5. 统计方法

1. 每日生成组间对比报表：`G1-G0`、`G2-G1`、`G3-G2`。
2. 采用 bootstrap 置信区间评估成功率差异是否稳定。
3. 对误召回率进行分域统计，定位分类策略问题。
4. 对成本指标做 P50/P95 双视角，避免平均值掩盖尾延迟。

## 6. 上线门禁（Go/No-Go）

满足以下条件才允许默认启用：

1. `G2 vs G0`：成功率提升 >= 8%，误召回增幅 <= 2%。
2. `G3 vs G2`：成功率再提升 >= 3%，long 污染率不升高。
3. token 增幅 <= 20%，P95 延迟增幅 <= 15%。
4. 连续 7 天无 P1 回归（错误写回、错误归档、上下文污染）。

## 7. 执行节奏（两周）

1. D1-D2：完成埋点、日志校验、dry-run。
2. D3-D4：整理样本与判分规则。
3. D5-D7：跑 `G0/G1/G2` 并出中期报告。
4. D8-D10：启用 `G3` 策略并复跑。
5. D11-D14：回归稳定性测试，形成上线建议。

## 8. 风险与偏差控制

1. 样本偏置风险：按域分层抽样并交叉复核标签。
2. 打分主观性：规则判分优先，人工只做争议复核。
3. 环境波动：固定模型版本和运行资源窗口。
4. 训练-评测泄漏：评测样本不进入写回数据源。
