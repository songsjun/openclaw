# Memory B++ 项目目录

本目录用于落地 OpenClaw 记忆插件的完整工程方案，目标是以最小侵入方式实现：

1. 时间分层记忆（short/mid/long/archive）
2. 分类与标签检索（domain/tags/deny_tags）
3. 基于使用与结果反馈的强化/淘汰机制
4. 可重复执行的评测与上线门禁

## 文档清单

1. [技术方案](./TECHNICAL_SOLUTION.md)
2. [评测方案](./EVALUATION_PLAN.md)
3. [实施计划](./IMPLEMENTATION_PLAN.md)

## 设计原则

1. 最小侵入：仅通过插件 hook 接入，不改 OpenClaw 核心业务逻辑。
2. 可解释：检索、排序、强化/淘汰规则可审计。
3. 可回滚：每个阶段都有独立开关和回退路径。
4. 数据主从分离：Markdown 为事实源，索引为可重建缓存。

## 交付物边界

1. 本目录仅定义方案与执行计划，不直接包含生产代码变更。
2. 实际代码实现应在 `extensions/memory-md-index/` 中按实施计划分阶段落地。
