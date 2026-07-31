#!/usr/bin/env bun
/**
 * kit-board — localhost status board (127.0.0.1 only). Explicit start; no auto-start.
 * Exposes .ai/ derived status — do not run on shared hosts without understanding sensitivity.
 */
import { resolve } from "node:path";
import {
  defaultProjectsPath,
  loadProjects,
  upsertProject,
} from "../projects-registry.ts";
import { PIPELINE_STAGES, scanProject, type WorkStatus } from "../status.ts";

const HOST = "127.0.0.1";
const PORT = Number(process.env.KIT_BOARD_PORT || 8787);
const registryPath = defaultProjectsPath();

upsertProject(registryPath, process.cwd());

const clients = new Set<ReadableStreamDefaultController<Uint8Array>>();
const enc = new TextEncoder();

function snapshot(): WorkStatus[] {
  const data = loadProjects(registryPath);
  return data.projects.flatMap((p) => scanProject(p.path, p.id));
}

function pageHtml(): string {
  return `<!DOCTYPE html>
<html lang="en">
<head>
<meta charset="utf-8"/>
<title>Agent Dev Kit — status board</title>
<style>
  :root { font-family: ui-sans-serif, system-ui, sans-serif; color: #1a1a1a; background: #f6f5f2; }
  body { margin: 1.5rem; max-width: 960px; }
  h1 { font-size: 1.25rem; }
  .legend { display: flex; flex-wrap: wrap; gap: .4rem; margin: 1rem 0; }
  .chip { font-size: .75rem; padding: .2rem .5rem; background: #e8e4dc; border-radius: 4px; }
  table { width: 100%; border-collapse: collapse; background: #fff; }
  th, td { text-align: left; padding: .5rem .6rem; border-bottom: 1px solid #ddd; font-size: .9rem; }
  .warn { color: #666; font-size: .8rem; }
</style>
</head>
<body>
<h1>Kit status board</h1>
<p class="warn">Loopback only (${HOST}). Read-only view of configured project <code>.ai/</code> trees. Not a second tracker.</p>
<div class="legend">${PIPELINE_STAGES.map((s) => `<span class="chip">${s}</span>`).join("")}</div>
<table>
<thead><tr><th>Project</th><th>Work</th><th>Stage</th><th>Spec</th><th>Updated</th></tr></thead>
<tbody id="rows"></tbody>
</table>
<script>
const tbody = document.getElementById('rows');
function render(rows) {
  tbody.innerHTML = rows.map(r => '<tr>' +
    [r.project, r.work_ref, r.stage, r.spec_key || '-', r.updated_at || '-']
      .map(c => '<td>' + String(c).replace(/</g,'&lt;') + '</td>').join('') +
    '</tr>').join('') || '<tr><td colspan="5">(no work items)</td></tr>';
}
fetch('/api/status').then(r => r.json()).then(render);
const es = new EventSource('/api/events');
es.onmessage = (ev) => { try { render(JSON.parse(ev.data)); } catch (_) {} };
</script>
</body>
</html>`;
}

function broadcast(rows: WorkStatus[]) {
  const payload = `data: ${JSON.stringify(rows)}\n\n`;
  for (const c of clients) {
    try {
      c.enqueue(enc.encode(payload));
    } catch {
      clients.delete(c);
    }
  }
}

let lastJson = "";
setInterval(() => {
  const rows = snapshot();
  const j = JSON.stringify(rows);
  if (j !== lastJson) {
    lastJson = j;
    broadcast(rows);
  }
}, 1500);

const server = Bun.serve({
  hostname: HOST,
  port: PORT,
  fetch(req) {
    const url = new URL(req.url);
    if (url.pathname === "/api/status") {
      return Response.json(snapshot());
    }
    if (url.pathname === "/api/events") {
      const stream = new ReadableStream({
        start(controller) {
          clients.add(controller);
          controller.enqueue(enc.encode(`data: ${JSON.stringify(snapshot())}\n\n`));
        },
        cancel() {
          /* client gone */
        },
      });
      return new Response(stream, {
        headers: {
          "Content-Type": "text/event-stream",
          "Cache-Control": "no-cache",
          Connection: "keep-alive",
        },
      });
    }
    if (url.pathname === "/" || url.pathname === "/index.html") {
      return new Response(pageHtml(), { headers: { "Content-Type": "text/html; charset=utf-8" } });
    }
    return new Response("Not found", { status: 404 });
  },
});

console.error(
  `kit board on http://${HOST}:${server.port}/ (explicit start; loopback only; may expose .ai/ content)`,
);
