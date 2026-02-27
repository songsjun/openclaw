# Step 1 Report: Data Model Upgrade

## Goal

Upgrade memory data model to support:

1. `mid/<domain>/YYYY-MM-DD.md` classified storage.
2. Frontmatter metadata on newly appended mid entries.
3. Backward-compatible reads for legacy markdown entries without frontmatter.

## Implemented Changes

1. `store.ts`

- Added domain-based mid write path (`mid/<domain>/...`).
- Added metadata frontmatter for new mid entries.
- Added metadata parsing with defaults for legacy docs.
- Added metadata on `listDocuments()` output.

2. `writeback.ts`

- Added lightweight domain inference (`programming|ops|product|people|general`).
- Added tag inference and writeback metadata (`domain`, `tags`, `confidence`, `ttl`).

3. `maintenance.ts`

- Dedupe now scans `mid/` recursively (compatible with domain subdirectories).

4. Tests updated

- `store.test.ts`: verifies domain path + frontmatter + legacy fallback metadata.
- `writeback.test.ts`: verifies domain metadata is written in mid files.
- `maintenance.test.ts`: verifies recursive dedupe with new block shape.

## Validation Commands

```bash
pnpm exec oxfmt --check extensions/memory-md-index/*.ts
pnpm exec vitest run --config vitest.config.ts extensions/memory-md-index/*.test.ts
```

## Validation Result

- Format: passed.
- Tests: `7` files passed, `21` tests passed, `0` failed.

## Step 1 Acceptance Check

1. `mid/<domain>/...` 写入生效：通过。
2. frontmatter 元数据写入：通过。
3. 旧条目兼容读取默认值：通过。

Status: `PASSED`
