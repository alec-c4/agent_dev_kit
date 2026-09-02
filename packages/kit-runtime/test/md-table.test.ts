import { describe, expect, test } from "bun:test";
import { escapeCell, splitRow } from "../src/md-table.ts";

describe("md-table cell escaping", () => {
  test("splits a plain row", () => {
    expect(splitRow("| a | b | c |")).toEqual(["a", "b", "c"]);
  });

  test("a pipe inside a cell does not shift columns", () => {
    const row = `| ${["a", escapeCell("use A | not B"), "c"].join(" | ")} |`;
    expect(splitRow(row)).toEqual(["a", "use A | not B", "c"]);
  });

  test("round-trips backslashes", () => {
    const value = "path\\to | thing";
    const row = `| ${escapeCell(value)} | tail |`;
    expect(splitRow(row)).toEqual([value, "tail"]);
  });

  test("newlines collapse to spaces", () => {
    expect(escapeCell("one\ntwo")).toBe("one two");
  });

  test("reads legacy rows escaped without backslash doubling", () => {
    expect(splitRow("| a \\| b | tail |")).toEqual(["a | b", "tail"]);
  });

  test("ignores non-table lines", () => {
    expect(splitRow("no pipes here")).toEqual([]);
  });
});
