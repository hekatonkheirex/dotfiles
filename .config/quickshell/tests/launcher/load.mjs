// Loads a `.pragma library` QML JS module from config/launcher without a QML runtime.
// Usage: const M = load("Calc.js", ["evaluate"])
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
export function load(file, names) {
  const src = readFileSync(fileURLToPath(new URL("../../config/launcher/" + file, import.meta.url)), "utf8")
    .replace(/^\.pragma library$/m, "")
  return new Function('"use strict";\n' + src + "; return { " + names.join(", ") + " }")()
}
