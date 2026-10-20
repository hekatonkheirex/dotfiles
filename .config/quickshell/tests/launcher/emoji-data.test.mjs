// Gate test: node tests/launcher/emoji-data.test.mjs
// EmojiData.js must match what scripts/gen-emoji.py produces from the installed font.
import assert from "node:assert/strict"
import { existsSync, readFileSync } from "node:fs"
import { spawnSync } from "node:child_process"
import { fileURLToPath } from "node:url"

const src = readFileSync(fileURLToPath(new URL("../../config/launcher/EmojiData.js", import.meta.url)), "utf8").replace(/^\.pragma library$/m, "")
const EMOJI = new Function('"use strict";\n' + src + "; return EMOJI")()
assert.ok(EMOJI.length > 1000, "expected over 1000 emoji, got " + EMOJI.length)
assert.equal(new Set(EMOJI.map(e => e[0])).size, EMOJI.length, "no duplicate characters")
for (const [ch, name] of EMOJI) {
  assert.ok(ch.length >= 1 && name.length > 0 && name === name.toLowerCase(), "bad row " + ch)
  assert.ok([...ch].length === 1, "single code point only: " + ch)
}
for (const need of ["thumbs up", "grinning face", "red heart", "fire", "rocket", "party popper"]) {
  assert.ok(EMOJI.some(e => e[1] === need), "missing " + need)
}
if (existsSync("/usr/share/fonts/noto/NotoColorEmoji.ttf")) {
  const r = spawnSync("python3", ["-I", fileURLToPath(new URL("../../scripts/gen-emoji.py", import.meta.url)), "--check"])
  assert.equal(r.status, 0, "EmojiData.js is stale: run python3 scripts/gen-emoji.py")
}
console.log("emoji-data: ok")
