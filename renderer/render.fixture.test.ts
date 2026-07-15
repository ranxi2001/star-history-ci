import axios from "axios";
import { existsSync, mkdtempSync, readFileSync, rmSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { setTimeout as delay } from "node:timers/promises";

const pngData =
  "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAusB9Y9Zp0AAAAAASUVORK5CYII=";

let requests = 0;
axios.defaults.adapter = async (config) => {
  requests += 1;
  const url = String(config.url);
  let data: unknown;

  if (url.includes("/stargazers")) {
    data = [{ starred_at: "2026-07-01T00:00:00Z" }];
  } else if (url.endsWith("/repos/fixture/example")) {
    data = { stargazers_count: 1 };
  } else if (url.endsWith("/users/fixture")) {
    data = { avatar_url: pngData };
  } else {
    throw new Error(`Unexpected fixture request: ${url}`);
  }

  return {
    config,
    data,
    headers: {},
    status: 200,
    statusText: "OK",
  };
};

const dir = mkdtempSync(join(tmpdir(), "star-history-render-"));
const svg = join(dir, "chart.svg");
const png = join(dir, "chart.png");
const signature = join(dir, "chart.sig");

process.env.GITHUB_TOKEN = "fixture-token";
process.argv = [
  process.execPath,
  "render.ts",
  "--repos",
  "fixture/example",
  "--theme",
  "light",
  "--type",
  "Date",
  "--width",
  "480",
  "--output",
  svg,
  "--png",
  png,
  "--signature",
  signature,
];

await import("./render.ts");

const deadline = Date.now() + 10_000;
while (!existsSync(png) && Date.now() < deadline) {
  await delay(25);
}

try {
  const svgText = readFileSync(svg, "utf8");
  const pngBytes = readFileSync(png);
  const sigText = readFileSync(signature, "utf8");

  if (!/<svg\b/i.test(svgText)) throw new Error("Fixture renderer did not produce SVG");
  if (pngBytes.subarray(0, 4).toString("hex") !== "89504e47") {
    throw new Error("Fixture renderer did not produce PNG");
  }
  if (!/^[0-9a-f]{64}$/.test(sigText)) throw new Error("Fixture signature is invalid");
  if (requests !== 4) throw new Error(`Expected 4 fixture requests, got ${requests}`);

  process.stdout.write("renderer fixture test passed\n");
} finally {
  rmSync(dir, { recursive: true, force: true });
}
