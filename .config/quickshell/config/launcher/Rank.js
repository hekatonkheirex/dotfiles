.pragma library

// Fuzzy ranking for launcher items. An item is any object with `id` and some
// of name, generic_name, keywords, categories, comment, aliases (array).
// Every query term must match at least one field. Higher score sorts first.

var FIELD_WEIGHT = { name: 1, generic_name: 0.6, keywords: 0.4, categories: 0.25, comment: 0.2 }
var ALIAS_SCORE = 5000

function wordStart(text, term) {
  var i = text.indexOf(term)
  while (i !== -1) {
    if (i === 0 || /[^a-z0-9]/.test(text.charAt(i - 1))) return true
    i = text.indexOf(term, i + 1)
  }
  return false
}

// Characters of term appear in order in text. Tighter spans score higher.
function subsequence(text, term) {
  if (term.length < 2) return 0
  var pos = 0
  var first = -1
  var last = -1
  for (var i = 0; i < term.length; i++) {
    pos = text.indexOf(term.charAt(i), pos)
    if (pos === -1) return 0
    if (first === -1) first = pos
    last = pos
    pos++
  }
  var gap = (last - first + 1) - term.length
  return Math.max(10, 100 - gap * 5)
}

function textScore(text, term, fuzzy) {
  if (!text) return 0
  if (text === term) return 1000
  if (text.indexOf(term) === 0) return 700
  if (wordStart(text, term)) return 500
  if (text.indexOf(term) !== -1) return 300
  return fuzzy ? subsequence(text, term) : 0
}

function itemScore(item, terms, query) {
  var total = 0
  for (var t = 0; t < terms.length; t++) {
    var best = 0
    for (var f in FIELD_WEIGHT) {
      // Subsequence matches are only trusted on the name; in long keyword
      // text they match almost anything.
      var s = textScore(String(item[f] || "").toLowerCase(), terms[t], f === "name") * FIELD_WEIGHT[f]
      if (s > best) best = s
    }
    if (best === 0) return 0
    total += best
  }
  var name = String(item.name || "").toLowerCase()
  if (name === query) total += 1000
  else if (name.indexOf(query) === 0) total += 400
  return total
}

function aliasMatch(item, query) {
  var a = item.aliases
  if (!a) return false
  for (var i = 0; i < a.length; i++) if (String(a[i]).toLowerCase() === query) return true
  return false
}

// Returns items (same objects) with a `score` property set on a copy.
function rank(items, query, boostMap) {
  var q = String(query || "").toLowerCase().trim()
  var boost = boostMap || {}
  var terms = q === "" ? [] : q.split(/\s+/)
  var out = []
  for (var i = 0; i < items.length; i++) {
    var item = items[i]
    var b = boost[item.id] || 0
    var s
    if (q === "") s = b
    else if (aliasMatch(item, q)) s = ALIAS_SCORE + b
    else {
      s = itemScore(item, terms, q)
      if (s === 0) continue
      s += b
    }
    out.push({ item: item, score: s })
  }
  out.sort(function(x, y) {
    if (y.score !== x.score) return y.score - x.score
    return String(x.item.name || "").localeCompare(String(y.item.name || ""))
  })
  return out
}
