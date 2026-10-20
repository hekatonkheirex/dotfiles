.pragma library

// Emoji rows from EmojiData.js ([char, name] pairs). Used behind the ":" prefix.

function toItems(data) {
  var out = []
  for (var i = 0; i < data.length; i++) {
    out.push({
      id: "emoji:" + data[i][0], kind: "emoji", name: data[i][1], comment: "",
      keywords: "", icon: "", glyph: data[i][0], tag: "Emoji", payload: { text: data[i][0] }
    })
  }
  return out
}
