# Step 2 Report: Route Hints and Pre-Filter

## Goal

Implement route-aware memory retrieval with minimal intrusion:

1. Infer domain/tag hints from query.
2. Pre-filter retrieval candidates before backend search.
3. Enforce deny-tag exclusion and controlled cross-domain fallback.

## Implemented Changes

1. Added `routing.ts`

- `inferRoutingHints(query, denyTags)` for domain/tag hints.
- `filterDocumentsForRouting(docs, hints, fallbackCrossDomainDocs)` for candidate filtering.

2. Integrated routing in `index.ts`

- Inside `before_prompt_build`, apply route hints + pre-filter before retrieval backend call.
- Added debug logs for routed domain, rejected docs, and fallback docs.

3. Config/schema updates

- Added `route` config section:
  - `enabled`
  - `fallbackCrossDomainDocs`
  - `denyTags`
- Updated `openclaw.plugin.json` accordingly.

4. Tests

- Added `routing.test.ts` to validate domain inference and filtering behavior.
- Added index integration test for route filtering in `index.test.ts`.
- Extended config tests for new route config keys and validation.

## Validation Commands

```bash
pnpm exec oxfmt --check extensions/memory-md-index/*.ts
pnpm exec vitest run --config vitest.config.ts extensions/memory-md-index/*.test.ts
```

## Validation Result

- Format: passed.
- Tests: `8` files passed, `25` tests passed, `0` failed.

## Step 2 Acceptance Check

1. 路由提示生成并参与检索前过滤：通过。
2. `deny_tags` 可阻断召回：通过。
3. 跨域兜底召回数量可控：通过。

Status: `PASSED`
