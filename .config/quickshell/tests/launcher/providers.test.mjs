// Gate test: node tests/launcher/providers.test.mjs
import assert from "node:assert/strict"
import { load } from "./load.mjs"

const Q = load("Quicklinks.js", ["DEFAULTS", "normalize", "merge", "expand", "matchKeyword", "fallbacks", "toItems", "keywordItem", "fallbackItems"])
const S = load("Snippets.js", ["expand", "normalize", "toItems", "uuid"])
const W = load("Windows.js", ["parse", "focusArgv", "closeArgv", "layoutArgv", "toItems", "layoutItems", "LAYOUT"])
const A = load("ActionPanel.js", ["actionsFor"])

// ---- quicklinks
assert.equal(Q.expand("https://x/?q={query}", "a b&c=d/é"), "https://x/?q=a%20b%26c%3Dd%2F%C3%A9", "query is URL-encoded")
assert.equal(Q.expand("https://x/{query}{query}", "z"), "https://x/zz", "all placeholders expand")
assert.equal(Q.expand("https://x/?q={query}", "$& $1"), "https://x/?q=%24%26%20%241", "replacement patterns in input stay literal")
assert.equal(Q.expand("https://x/?c={clipboard}", "", "a b"), "https://x/?c=a%20b")
const links = Q.merge([
  { name: "Mine", url: "https://mine.example/?q={query}", keyword: "G" },
  { name: "Evil", url: "javascript:alert(1)", keyword: "x" },
  { name: "File", url: "file:///etc/passwd", keyword: "f" },
  { name: "Data", url: "data:text/html,hi", keyword: "d" },
  { name: "", url: "https://blank.example" }, null, 7, { name: "NoUrl" },
  { name: "Mail", url: "mailto:{query}", keyword: "m" },
])
assert.deepEqual(links.map(l => l.name).filter(n => ["Evil", "File", "Data"].includes(n)), [], "unsafe schemes are refused")
assert.equal(links.find(l => l.keyword === "g").name, "Mine", "user keyword overrides the default")
assert.equal(links.filter(l => l.keyword === "g").length, 1)
assert.ok(links.find(l => l.keyword === "gh"), "other defaults survive")
assert.deepEqual(Q.merge("nope").map(l => l.keyword), Q.DEFAULTS.map(l => l.keyword), "garbage input falls back to defaults")
const km = Q.matchKeyword(links, "GH  quick shell ")
assert.equal(km.link.keyword, "gh"); assert.equal(km.query, "quick shell")
assert.equal(Q.matchKeyword(links, "gh"), null, "keyword alone is not a query")
assert.equal(Q.matchKeyword(links, "gh   "), null)
assert.equal(Q.matchKeyword(links, "zz foo"), null)
assert.equal(Q.keywordItem(km, "").payload.url, "https://github.com/search?q=quick%20shell")
assert.equal(Q.fallbackItems(links, "cats & dogs")[0].payload.url.includes("cats%20%26%20dogs"), true)
assert.deepEqual(Q.toItems(links).find(i => i.id === "link:gh").aliases, ["gh"])

// ---- snippets
const ctx = { now: new Date(2026, 9, 19, 7, 5), clipboard: "CLIP {date}", rand: () => 0 }
assert.equal(S.expand("{date}|{time}|{day}|{datetime}", ctx), "2026-10-19|07:05|Monday|2026-10-19 07:05")
assert.equal(S.expand("a{clipboard}b", ctx), "aCLIP {date}b", "expansion is single pass")
assert.equal(S.expand("x{cursor}y", ctx), "xy")
assert.equal(S.expand("{unknown} {date}", ctx), "{unknown} 2026-10-19")
assert.match(S.expand("{uuid}", { now: ctx.now }), /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/)
assert.deepEqual(S.normalize([{ name: " Sig ", text: "hi", keyword: " SIG " }, { name: "", text: "x" }, { name: "n" }, 3]), [{ name: "Sig", text: "hi", keyword: "sig" }])
const si = S.toItems(S.normalize([{ name: "Today", text: "It is {date}\n\n  ok", keyword: "td" }]), ctx)[0]
assert.equal(si.comment, "It is 2026-10-19 ok"); assert.equal(si.payload.text, "It is 2026-10-19\n\n  ok", "payload keeps original whitespace")

// ---- windows
const wj = JSON.stringify([{ id: 4, title: "README — Zed", app_id: "dev.zed.Zed", workspace_id: 2, is_focused: true }, { id: 9, title: null, app_id: null }, { nope: 1 }, null])
const wins = W.parse(wj)
assert.equal(wins.length, 2); assert.equal(wins[0].focused, true); assert.equal(wins[1].title, "")
assert.deepEqual(W.parse("garbage"), []); assert.deepEqual(W.parse('{"a":1}'), [])
assert.deepEqual(W.focusArgv(4), ["niri", "msg", "action", "focus-window", "--id", "4"])
assert.deepEqual(W.closeArgv(4), ["niri", "msg", "action", "close-window", "--id", "4"])
const wi = W.toItems(wins, { "dev.zed.zed": "Zed" })
assert.equal(wi[0].comment, "Zed"); assert.equal(wi[1].name, "Window", "untitled window falls back to a label")
assert.deepEqual(W.layoutArgv(W.LAYOUT.find(c => c.id === "win-w50"), 4), ["niri", "msg", "action", "set-window-width", "--id", "4", "50%"])
assert.deepEqual(W.layoutItems(null), [], "no focused window, no layout commands")
assert.equal(W.layoutItems(4).length, W.LAYOUT.length)
assert.deepEqual(W.layoutItems(4)[2].payload.argv.slice(-2), ["--id", "4"])

// ---- action panel
const ids = (item, o) => A.actionsFor(item, o).map(a => a.id)
assert.deepEqual(ids({ kind: "app", terminal: false }), ["open", "open-terminal", "copy-command"])
assert.deepEqual(ids({ kind: "app", terminal: true }), ["open", "copy-command"])
assert.deepEqual(ids({ kind: "calc" }), ["copy", "copy-expression"])
assert.deepEqual(ids({ kind: "emoji" }), ["copy"]); assert.deepEqual(ids({ kind: "emoji" }, { canType: true }), ["copy", "paste"])
assert.deepEqual(ids({ kind: "window" }), ["focus-window", "close-window"])
assert.equal(A.actionsFor({ kind: "window" })[1].destructive, true)
assert.deepEqual(ids({ kind: "clipboard" }), ["restore", "delete-clipboard"])
assert.deepEqual(ids(null), []); assert.deepEqual(ids({ kind: "mystery" }), [])
console.log("providers: ok")
