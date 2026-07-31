#!/usr/bin/env bun
import { resolve } from "node:path";
import { defaultProjectsPath, upsertProject } from "../projects-registry.ts";

const path = resolve(process.argv[2] || process.cwd());
const entry = upsertProject(defaultProjectsPath(), path);
console.log(JSON.stringify(entry, null, 2));
console.error(`Registered in ${defaultProjectsPath()}`);
