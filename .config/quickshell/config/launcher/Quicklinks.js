.pragma library

// Quicklinks: "gh quickshell" opens a URL template with the rest of the line.
// Templates use {query} (URL-encoded) and {clipboard} (URL-encoded).

var SCHEMES = /^(https?|mailto):/i

var DEFAULTS = [
  { name: "Google", keyword: "g", url: "https://www.google.com/search?q={query}", fallback: true },
  { name: "DuckDuckGo", keyword: "ddg", url: "https://duckduckgo.com/?q={query}" },
  { name: "GitHub", keyword: "gh", url: "https://github.com/search?q={query}" },
  { name: "YouTube", keyword: "yt", url: "https://www.youtube.com/results?search_query={query}" },
  { name: "Wikipedia", keyword: "w", url: "https://en.wikipedia.org/w/index.php?search={query}" },
  { name: "Arch Wiki", keyword: "aw", url: "https://wiki.archlinux.org/index.php?search={query}" }
]

// Keep only well-formed entries. javascript:, file: and data: URLs are
// refused so a shared launcher.json cannot run code or read local files.
function normalize(list) {
  var out = []
  if (!Array.isArray(list)) return out
  for (var i = 0; i < list.length; i++) {
    var l = list[i]
    if (!l || typeof l.name !== "string" || typeof l.url !== "string") continue
    if (l.name.trim() === "" || !SCHEMES.test(l.url.trim())) continue
    out.push({
      name: l.name.trim(),
      url: l.url.trim(),
      keyword: typeof l.keyword === "string" ? l.keyword.trim().toLowerCase() : "",
      fallback: l.fallback === true
    })
  }
  return out
}

// User links override defaults with the same keyword, and inherit that
// default's fallback flag so replacing Google keeps a web fallback.
function merge(user) {
  var mine = normalize(user)
  var taken = {}
  for (var i = 0; i < mine.length; i++) if (mine[i].keyword) taken[mine[i].keyword] = mine[i]
  var out = mine.slice()
  for (var j = 0; j < DEFAULTS.length; j++) {
    var d = DEFAULTS[j]
    if (taken[d.keyword]) taken[d.keyword].fallback = taken[d.keyword].fallback || d.fallback === true
    else out.push(d)
  }
  return out
}

function expand(url, query, clipboard) {
  return url
    .replace(/\{query\}/g, function() { return encodeURIComponent(query || "") })
    .replace(/\{clipboard\}/g, function() { return encodeURIComponent(clipboard || "") })
}

// "gh foo bar" -> { link, query: "foo bar" } when `gh` is a keyword.
function matchKeyword(links, text) {
  var t = String(text || "").trim()
  var space = t.search(/\s/)
  if (space <= 0) return null
  var word = t.slice(0, space).toLowerCase()
  var rest = t.slice(space).trim()
  if (rest === "") return null
  for (var i = 0; i < links.length; i++) {
    if (links[i].keyword === word) return { link: links[i], query: rest }
  }
  return null
}

function fallbacks(links) {
  return links.filter(function(l) { return l.fallback })
}

function host(url) {
  var m = /^[a-z]+:\/\/([^\/?#]+)/i.exec(url)
  return m ? m[1] : url
}

// Browsable entries: typing the name or keyword alone opens the link with an
// empty query.
function toItems(links) {
  return links.map(function(l) {
    return {
      id: "link:" + (l.keyword || l.name), kind: "quicklink", name: l.name, comment: host(l.url),
      keywords: "quicklink web search " + l.keyword, aliases: l.keyword ? [l.keyword] : [],
      icon: "link", tag: "Quicklink", payload: { url: expand(l.url, "", "") }
    }
  })
}

// "gh foo" -> row that opens the expanded URL.
function keywordItem(match, clipboard) {
  var url = expand(match.link.url, match.query, clipboard)
  return {
    id: "linkq:" + match.link.keyword, kind: "quicklink", name: match.link.name + ": " + match.query,
    comment: url, keywords: "", icon: "link", tag: "Quicklink", payload: { url: url }
  }
}

function fallbackItems(links, text) {
  return fallbacks(links).map(function(l) {
    return {
      id: "fallback:" + (l.keyword || l.name), kind: "quicklink", name: "Search " + l.name + " for “" + text + "”",
      comment: "", keywords: "", icon: "search", tag: "Fallback", payload: { url: expand(l.url, text, "") }
    }
  })
}
