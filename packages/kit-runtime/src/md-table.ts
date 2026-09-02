/**
 * Pipe-table cell escaping shared by the findings and lessons ledgers.
 *
 * Cells are written with `|` and `\` escaped; `splitRow` is the matching
 * reader. Splitting on a raw `|` would shift every later column whenever a
 * summary or guide contains a pipe.
 */

export function escapeCell(value: string): string {
  return value
    .replace(/\\/g, "\\\\")
    .replace(/\|/g, "\\|")
    .replace(/\r?\n/g, " ");
}

/** Split one markdown table row, honouring `\|` and `\\`. */
export function splitRow(line: string): string[] {
  const trimmed = line.trim();
  if (!trimmed.startsWith("|")) return [];
  const inner = trimmed.slice(1, trimmed.endsWith("|") ? -1 : undefined);
  const cells: string[] = [];
  let cur = "";
  for (let i = 0; i < inner.length; i++) {
    const ch = inner[i];
    if (ch === "\\" && (inner[i + 1] === "|" || inner[i + 1] === "\\")) {
      cur += inner[i + 1];
      i++;
      continue;
    }
    if (ch === "|") {
      cells.push(cur.trim());
      cur = "";
      continue;
    }
    cur += ch;
  }
  cells.push(cur.trim());
  return cells;
}
