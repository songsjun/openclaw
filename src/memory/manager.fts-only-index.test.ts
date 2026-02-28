import fs from "node:fs/promises";
import os from "node:os";
import path from "node:path";
import { afterEach, describe, expect, it, vi } from "vitest";
import { getMemorySearchManager } from "./index.js";
import "./test-runtime-mocks.js";

vi.mock("./embeddings.js", () => ({
  createEmbeddingProvider: async () => ({
    requestedProvider: "auto",
    provider: null,
    providerUnavailableReason: "No API key found",
  }),
}));

describe("memory index (fts-only mode)", () => {
  const managers = new Set<
    NonNullable<Awaited<ReturnType<typeof getMemorySearchManager>>["manager"]>
  >();
  const roots = new Set<string>();

  afterEach(async () => {
    await Promise.all(Array.from(managers).map(async (manager) => await manager.close?.()));
    managers.clear();
    await Promise.all(
      Array.from(roots).map(async (root) => await fs.rm(root, { recursive: true, force: true })),
    );
    roots.clear();
  });

  it("indexes and searches memory files without embeddings, including forced reindex", async () => {
    const root = await fs.mkdtemp(path.join(os.tmpdir(), "openclaw-mem-fts-only-"));
    roots.add(root);

    const workspaceDir = path.join(root, "workspace");
    const memoryDir = path.join(workspaceDir, "memory");
    const indexPath = path.join(workspaceDir, "index.sqlite");
    await fs.mkdir(memoryDir, { recursive: true });
    await fs.writeFile(
      path.join(memoryDir, "notes.md"),
      "# Notes\nAlpha rollout check\nBeta fallback note\n",
    );

    type TestCfg = Parameters<typeof getMemorySearchManager>[0]["cfg"];
    const cfg: TestCfg = {
      agents: {
        defaults: {
          workspace: workspaceDir,
          memorySearch: {
            provider: "openai",
            store: { path: indexPath, vector: { enabled: false } },
            sync: { watch: false, onSessionStart: false, onSearch: false },
            query: { minScore: 0, hybrid: { enabled: true, vectorWeight: 0.5, textWeight: 0.5 } },
          },
        },
        list: [{ id: "main", default: true }],
      },
    };

    const result = await getMemorySearchManager({ cfg, agentId: "main" });
    expect(result.manager).not.toBeNull();
    if (!result.manager) {
      throw new Error("memory manager missing");
    }
    const manager = result.manager;
    managers.add(manager);

    await manager.sync?.({ reason: "test" });
    const firstStatus = manager.status();
    expect(firstStatus.provider).toBe("none");
    expect(firstStatus.custom).toMatchObject({ searchMode: "fts-only" });
    expect(firstStatus.files ?? 0).toBeGreaterThan(0);
    expect(firstStatus.chunks ?? 0).toBeGreaterThan(0);

    const firstResults = await manager.search("alpha");
    expect(firstResults.length).toBeGreaterThan(0);
    expect(firstResults[0]?.path).toContain("memory/notes.md");

    await manager.sync?.({ reason: "test-force", force: true });
    const secondStatus = manager.status();
    expect(secondStatus.files ?? 0).toBeGreaterThan(0);
    expect(secondStatus.chunks ?? 0).toBeGreaterThan(0);

    const secondResults = await manager.search("alpha");
    expect(secondResults.length).toBeGreaterThan(0);
  });
});
