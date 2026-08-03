#!/usr/bin/env bun
/** Print cache file relative path for project. */
import { cacheFilePath } from "../tracker-config.ts";

const projectDir = process.argv[2] || process.cwd();
console.log(cacheFilePath(projectDir));
