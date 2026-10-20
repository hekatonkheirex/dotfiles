// Gate test: node tests/launcher/rank.test.mjs
// Doubles as the golden ranking suite: each row is a query a person types and
// the item that must come first. No LLM is involved, so this is the eval lane.
import assert from "node:assert/strict"
import { load } from "./load.mjs"
const { rank } = load("Rank.js", ["rank"])
const { record, boosts, parse } = load("Frecency.js", ["record", "boosts", "parse", "decayed", "prune", "MAX_ENTRIES"])

const apps = [
  { id: "firefox", name: "Firefox", generic_name: "Web Browser", keywords: "internet www browser", categories: "Network;WebBrowser;", comment: "Browse the web" },
  { id: "brave", name: "Brave Origin", generic_name: "Web Browser", keywords: "internet www browser", categories: "Network;", comment: "Browse the web" },
  { id: "kitty", name: "kitty", generic_name: "Terminal", keywords: "terminal shell command", categories: "System;TerminalEmulator;", comment: "Fast, feature-rich, GPU based terminal" },
  { id: "nautilus", name: "Files", generic_name: "File Manager", keywords: "folder manager explore", categories: "Utility;FileManager;", comment: "Access and organize files" },
  { id: "zed", name: "Zed", generic_name: "Text Editor", keywords: "code editor", categories: "Utility;TextEditor;", comment: "A high-performance code editor" },
  { id: "gimp", name: "GNU Image Manipulation Program", generic_name: "Image Editor", keywords: "photo editor", categories: "Graphics;", comment: "Create images and edit photographs" },
  { id: "settings", name: "Settings", generic_name: "Settings", keywords: "preferences", categories: "Settings;", comment: "Change your preferences" },
  { id: "spotify", name: "Spotify", generic_name: "Music Player", keywords: "music audio", categories: "AudioVideo;", comment: "Online music streaming" },
]
const top = (q, items = apps, b) => { const r = rank(items, q, b); return r.length ? r[0].item.id : null }

const golden = [
  ["firefox", "firefox"], ["fire", "firefox"], ["ff", "firefox"], ["fx", "firefox"],
  ["kit", "kitty"], ["term", "kitty"], ["terminal", "kitty"],
  ["files", "nautilus"], ["file manager", "nautilus"], ["folder", "nautilus"],
  ["zed", "zed"], ["text editor", "zed"], ["gimp", "gimp"], ["image manip", "gimp"], ["photo", "gimp"],
  ["spot", "spotify"], ["music", "spotify"], ["set", "settings"], ["brave", "brave"],
]
for (const [q, want] of golden) assert.equal(top(q), want, `golden: "${q}" should rank ${want} first, got ${top(q)}`)

assert.deepEqual(rank(apps, "web browser").slice(0, 2).map(r => r.item.id).sort(), ["brave", "firefox"], "tie between two browsers")
// every term must match
assert.equal(top("firefox zzz"), null)
assert.equal(top("zzzz"), null)
// case and whitespace
assert.equal(top("  FIREFOX  "), "firefox")
// word-start beats mid-word substring
assert.equal(top("man", [{ id: "a", name: "Command" }, { id: "b", name: "Image Manager" }]), "b")
// prefix beats substring
assert.equal(top("ed", [{ id: "a", name: "Wedge" }, { id: "b", name: "Editor" }]), "b")
// fuzzy subsequence on name only
assert.equal(top("frfx"), "firefox")
assert.equal(top("grnd", [{ id: "x", name: "Terminal", keywords: "grand node" }]), null, "fuzzy never reads keywords")
// aliases win over everything
const withAlias = apps.map(a => a.id === "zed" ? { ...a, aliases: ["ff"] } : a)
assert.equal(top("ff", withAlias), "zed")
assert.equal(rank(withAlias, "ff")[0].score >= 5000, true)

// empty query: frecency order, then name
const now = Date.UTC(2026, 9, 19)
let store = {}
for (let i = 0; i < 5; i++) store = record(store, "kitty", now)
store = record(store, "zed", now)
const order = rank(apps, "", boosts(store, now)).map(r => r.item.id)
assert.deepEqual(order.slice(0, 2), ["kitty", "zed"])
assert.equal(order.length, apps.length, "empty query lists everything")
assert.deepEqual(order.slice(2), ["brave", "firefox", "nautilus", "gimp", "settings", "spotify"].sort((a, b) => apps.find(x => x.id === a).name.localeCompare(apps.find(x => x.id === b).name)))

// frecency breaks a near tie but cannot beat a clearly better match
const b = boosts(record({}, "brave", now), now)
assert.equal(top("browser", apps, b), "brave", "history breaks an exact tie")
let heavy = {}
for (let i = 0; i < 400; i++) heavy = record(heavy, "brave", now)
assert.equal(top("firefox", apps, boosts(heavy, now)), "firefox", "boost is capped, relevance wins")

// decay: a year-old habit is worth less than one use today
const old = boosts(record({}, "zed", now - 365 * 86400000), now)
assert.ok((old.zed || 0) < boosts(record({}, "zed", now), now).zed / 4)

// store hygiene
let big = {}
for (let i = 0; i < 650; i++) big = record(big, "app" + i, now + i)
assert.equal(Object.keys(big).length, 500)
assert.ok(big["app649"], "newest survives pruning")
assert.deepEqual(parse("not json"), {})
assert.deepEqual(parse('{"a":{"n":2,"t":5},"b":{"n":"x","t":1},"c":null}'), { a: { n: 2, t: 5 } })
assert.deepEqual(parse("[1,2]"), {})
console.log("rank: ok")
