// Gate test: node tests/launcher/root.test.mjs
// Composition of every provider the way LauncherPopup feeds Root.build.
import assert from "node:assert/strict"
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import { load } from "./load.mjs"

const { rank } = load("Rank.js", ["rank"])
const { evaluate } = load("Calc.js", ["evaluate"])
const R = load("Root.js", ["build", "appItems", "parseUserData", "shouldRemember"])
const Q = load("Quicklinks.js", ["merge", "matchKeyword", "toItems", "keywordItem", "fallbackItems"])
const S = load("Snippets.js", ["normalize", "toItems"])
const W = load("Windows.js", ["toItems", "layoutItems"])
const E = load("Emoji.js", ["toItems"])
const { boosts, record } = load("Frecency.js", ["boosts", "record"])
const emojiSrc = readFileSync(fileURLToPath(new URL("../../config/launcher/EmojiData.js", import.meta.url)), "utf8").replace(/^\.pragma library$/m, "")
const EMOJI = new Function('"use strict";\n' + emojiSrc + "; return EMOJI")()

const now = new Date(2026, 9, 19, 12, 0)
const desktop = [
  { name: "Firefox", comment: "Browse the web", generic_name: "Web Browser", keywords: "internet", categories: "Network;", argv: ["firefox"], terminal: false },
  { name: "kitty", comment: "Terminal", generic_name: "Terminal", keywords: "shell", categories: "System;", argv: ["kitty"], terminal: false },
  { name: "Zed", comment: "Editor", generic_name: "Text Editor", keywords: "code", categories: "Utility;", argv: ["zed"], terminal: false },
]
const commands = [{ id: "cmd:lock", kind: "command", name: "Lock session", comment: "Lock the desktop", keywords: "lock screen", icon: "lock", tag: "Command", payload: {} }]
const user = R.parseUserData(JSON.stringify({
  aliases: { FF: "firefox" },
  quicklinks: [{ name: "Docs", url: "https://docs.example/?q={query}", keyword: "doc" }],
  snippets: [{ name: "Email sign-off", text: "Best,\nRodrigo", keyword: "sig" }, { name: "Today", text: "{date}", keyword: "td" }],
}))
const links = Q.merge(user.quicklinks)
const state = {
  apps: R.appItems(desktop, user.aliases), commands,
  windows: W.toItems([{ id: 7, title: "Quickshell docs - Brave", appId: "brave", workspaceId: 1, focused: false }], {}).concat(W.layoutItems(7)),
  snippets: S.toItems(S.normalize(user.snippets), { now, clipboard: "" }),
  links: Q.toItems(links), emoji: E.toItems(EMOJI),
}
const search = (query, extra = {}) => R.build({
  query, ...state, calc: evaluate(query), boosts: {},
  keywordLink: (() => { const m = Q.matchKeyword(links, query); return m ? Q.keywordItem(m, "") : null })(),
  fallbacks: Q.fallbackItems(links, query), ...extra,
}, rank)
const names = (q, n = 5) => search(q).slice(0, n).map(i => i.name)
const kinds = (q) => search(q).map(i => i.kind)

// resting state: apps and commands only, no windows/snippets/links clutter
assert.deepEqual([...new Set(kinds(""))].sort(), ["app", "command"])
// frecency orders the resting state
let h = record(record({}, "app:zed", now.getTime()), "app:zed", now.getTime())
assert.equal(R.build({ query: "", ...state, boosts: boosts(h, now.getTime()) }, rank)[0].name, "Zed")

// calculator first, then ordinary matches
assert.equal(search("2+2")[0].kind, "calc"); assert.equal(search("2+2")[0].name, "= 4")
assert.equal(search("2+2")[0].payload.expression, "2+2 = 4")
assert.equal(search("5 km to mi")[0].name, "= 3.10685596119 mi")
assert.equal(search("2+2").some(i => i.kind === "quicklink" && i.tag === "Fallback"), false, "no web fallback after a calculation")
// alias from launcher.json
assert.equal(search("ff")[0].name, "Firefox")
// a keyword quicklink query comes first and carries the expanded URL
const gh = search("gh quickshell bar")[0]
assert.equal(gh.kind, "quicklink"); assert.equal(gh.payload.url, "https://github.com/search?q=quickshell%20bar")
assert.equal(search("doc hello world")[0].payload.url, "https://docs.example/?q=hello%20world")
// snippets and windows are searchable
assert.equal(search("sig")[0].kind, "snippet"); assert.equal(search("sig")[0].payload.text, "Best,\nRodrigo")
assert.equal(search("td")[0].payload.text, "2026-10-19")
assert.equal(search("quickshell docs").find(i => i.kind === "window").payload.windowId, 7)
assert.ok(search("half width").some(i => i.id === "win-w50"))
// the launcher's own typed text never matches random window layout rows
assert.equal(search("zzzzqq").every(i => i.tag === "Fallback"), true, "nothing matches: only fallbacks remain")
assert.equal(search("zzzzqq")[0].name, "Search Google for “zzzzqq”")
// fallback appears when results are thin, not when they are plentiful
assert.equal(search("firefox").some(i => i.tag === "Fallback"), true, "one hit is thin")
assert.equal(search("e").some(i => i.tag === "Fallback"), false, "many hits, no fallback")
// emoji behind ':'
assert.equal(search(":thumbs up")[0].glyph, "\u{1F44D}")
assert.equal(search(":thumbs up")[0].payload.text, "\u{1F44D}")
assert.ok(search(":heart").length > 3 && search(":heart").length <= 60)
assert.equal(search(":").length, 60, "bare colon lists emoji, capped at 60")
assert.equal(search(":zzzzzz").length, 0)
// cap
assert.ok(search("e").length <= 50)
// user data is defensive
for (const bad of ["", "nope", "[]", "null", '{"aliases":[1],"quicklinks":"x","snippets":{}}']) {
  const d = R.parseUserData(bad)
  assert.deepEqual([d.aliases, d.quicklinks, d.snippets].map(x => Object.keys(x).length), [0, 0, 0], "bad launcher.json: " + bad)
}
assert.deepEqual(R.parseUserData('{"aliases":{"A":"b","c":3}}').aliases, { a: "b" })
// app items
const kitty = state.apps.find(a => a.name === "kitty")
assert.equal(kitty.id, "app:kitty"); assert.deepEqual(kitty.argv, ["kitty"]); assert.equal(kitty.tag, "Application")
// frecency policy
for (const id of ["app:firefox", "cmd:lock", "link:gh", "snippet:sig", "win-w50"]) assert.equal(R.shouldRemember(id), true, id)
for (const id of ["calc", "emoji:\u{1F680}", "linkq:gh", "fallback:g", "win:7", "", null, undefined]) assert.equal(R.shouldRemember(id), false, String(id))
console.log("root: ok")
