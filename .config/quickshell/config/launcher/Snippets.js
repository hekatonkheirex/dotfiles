.pragma library

// Snippets: saved text with placeholders, copied (or typed) from the launcher.
// {date} 2026-10-19  {time} 14:05  {datetime}  {day} Monday  {clipboard}
// {uuid}  {cursor} is dropped (the launcher cannot place a caret).

var DAYS = ["Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"]

function pad(n) { return (n < 10 ? "0" : "") + n }

function uuid(rand) {
  var r = rand || Math.random
  return "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx".replace(/[xy]/g, function(c) {
    var v = Math.floor(r() * 16)
    return (c === "x" ? v : (v & 3) | 8).toString(16)
  })
}

function expand(template, ctx) {
  var now = ctx.now
  var date = now.getFullYear() + "-" + pad(now.getMonth() + 1) + "-" + pad(now.getDate())
  var time = pad(now.getHours()) + ":" + pad(now.getMinutes())
  var values = {
    date: date,
    time: time,
    datetime: date + " " + time,
    day: DAYS[now.getDay()],
    clipboard: ctx.clipboard || "",
    uuid: null,
    cursor: ""
  }
  // One pass, so a clipboard that contains "{date}" is not expanded again.
  return String(template).replace(/\{(date|time|datetime|day|clipboard|uuid|cursor)\}/g, function(m, key) {
    return key === "uuid" ? uuid(ctx.rand) : values[key]
  })
}

function normalize(list) {
  var out = []
  if (!Array.isArray(list)) return out
  for (var i = 0; i < list.length; i++) {
    var s = list[i]
    if (!s || typeof s.name !== "string" || typeof s.text !== "string" || s.name.trim() === "") continue
    out.push({
      name: s.name.trim(),
      text: s.text,
      keyword: typeof s.keyword === "string" ? s.keyword.trim().toLowerCase() : ""
    })
  }
  return out
}

function preview(text) {
  var one = String(text).replace(/\s+/g, " ").trim()
  return one.length > 90 ? one.slice(0, 87) + "…" : one
}

function toItems(snippets, ctx) {
  return snippets.map(function(s, i) {
    var text = expand(s.text, ctx)
    return {
      id: "snippet:" + (s.keyword || i + ":" + s.name), kind: "snippet", name: s.name, comment: preview(text),
      keywords: "snippet text " + s.keyword, aliases: s.keyword ? [s.keyword] : [],
      icon: "text_snippet", tag: "Snippet", payload: { text: text }
    }
  })
}
