.pragma library

// Composes the launcher's result list. Pure: the caller supplies provider
// output, this decides order, caps and which sections appear.
//
// build({ query, apps, commands, windows, snippets, links, emoji,
//         calc, keywordLink, fallbacks, boosts })
// Every list holds unified items (id, kind, name, comment, keywords, icon,
// tag, payload). calc is Calc.evaluate(query); keywordLink is
// Quicklinks.keywordItem(...) or null; fallbacks are Quicklinks.fallbackItems.

var MAX_RESULTS = 50
var MAX_EMOJI = 60
var FALLBACK_BELOW = 3

function rankedItems(items, query, boosts, rank) {
  var r = rank(items, query, boosts)
  var out = []
  for (var i = 0; i < r.length; i++) out.push(r[i].item)
  return out
}

function calcItem(calc) {
  return {
    id: "calc", kind: "calc", name: "= " + calc.display, comment: calc.expression, keywords: "",
    icon: "calculate", tag: "Calculator", payload: { text: calc.copy, expression: calc.expression + " = " + calc.copy }
  }
}

function build(input, rank) {
  var q = String(input.query || "").trim()
  var boosts = input.boosts || {}

  if (q.charAt(0) === ":") {
    return rankedItems(input.emoji, q.slice(1).trim(), {}, rank).slice(0, MAX_EMOJI)
  }

  var out = []
  if (input.calc) out.push(calcItem(input.calc))
  if (input.keywordLink) out.push(input.keywordLink)

  var pool = [].concat(input.apps, input.commands, input.windows, input.snippets, input.links)
  var ranked = rankedItems(pool, q, boosts, rank)
  if (q === "") {
    // Resting state: apps and commands only, most used first.
    ranked = ranked.filter(function(it) { return it.kind === "app" || it.kind === "command" || it.kind === "action" })
  }
  out = out.concat(ranked).slice(0, MAX_RESULTS)

  if (q !== "" && !input.calc && ranked.length < FALLBACK_BELOW) out = out.concat(input.fallbacks || [])
  return out
}

// Desktop entries from bin/desktop-parser.py -> unified items. aliasMap is
// { "ff": "Firefox" } (alias -> app name, case-insensitive).
function appItems(apps, aliasMap) {
  var byName = {}
  for (var alias in (aliasMap || {})) {
    var target = String(aliasMap[alias]).toLowerCase()
    if (!byName[target]) byName[target] = []
    byName[target].push(alias.toLowerCase())
  }
  return apps.map(function(a) {
    var key = String(a.name).toLowerCase()
    return {
      id: "app:" + key, kind: "app", name: a.name, comment: a.comment || "", generic_name: a.generic_name || "",
      keywords: a.keywords || "", categories: a.categories || "", icon: a.icon || "", tag: "Application",
      aliases: byName[key] || [], argv: a.argv, terminal: a.terminal === true, payload: {}
    }
  })
}

// ~/.config/quickshell/launcher.json. Anything malformed is ignored so a typo
// never takes the launcher down.
function parseUserData(text) {
  var empty = { aliases: {}, quicklinks: [], snippets: [] }
  try {
    var raw = JSON.parse(text)
    if (!raw || typeof raw !== "object" || Array.isArray(raw)) return empty
    var aliases = {}
    if (raw.aliases && typeof raw.aliases === "object" && !Array.isArray(raw.aliases)) {
      for (var k in raw.aliases) if (typeof raw.aliases[k] === "string") aliases[k.toLowerCase()] = raw.aliases[k]
    }
    return {
      aliases: aliases,
      quicklinks: Array.isArray(raw.quicklinks) ? raw.quicklinks : [],
      snippets: Array.isArray(raw.snippets) ? raw.snippets : []
    }
  } catch (e) {
    return empty
  }
}

// Only durable items earn frecency. One-off rows (calculator, emoji, typed
// quicklink queries, fallbacks, open windows) would only fill the history.
function shouldRemember(id) {
  return /^(app:|cmd:|link:|snippet:|win-)/.test(String(id || ""))
}
