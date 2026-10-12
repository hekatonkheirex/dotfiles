.pragma library

// Bar surface forms. Geometry lives here (pure, tested in tests/bar-form)
// so Bar.qml only binds numbers.
//   full  edge to edge, flush with the screen edge
//   fit   inset rounded frame, floating off the edge
//   dock  narrower body flush with the edge, open desktop at both ends
//   notch dock body with concave shoulders flowing into the edge
var FORMS = ["full", "fit", "dock", "notch"]

function normalize(value) {
  return FORMS.indexOf(value) >= 0 ? value : "full"
}

// edgeGap: space between the screen edge and the bar (reserved by the panel).
// sideInset: space between the screen ends and the bar body along its axis.
// shoulder: size of each concave flare (notch only).
// roundNear: round the corners on the screen-edge side too.
// flat: no rounding at all (full).
function metrics(form, o) {
  switch (normalize(form)) {
  case "fit":
    return { edgeGap: o.spacingSmall, sideInset: o.spacingSmall, shoulder: 0, roundNear: true, flat: false }
  case "dock":
    return { edgeGap: 0, sideInset: o.barWidth, shoulder: 0, roundNear: false, flat: false }
  case "notch":
    return { edgeGap: 0, sideInset: o.barWidth, shoulder: o.spacingLarge, roundNear: false, flat: false }
  default:
    return { edgeGap: 0, sideInset: 0, shoulder: 0, roundNear: false, flat: true }
  }
}

// SVG path of the two concave shoulders, in the coordinates of the item that
// holds the bar body. g: { edge: "top"|"bottom"|"left"|"right", x, y, w, h }
// is the body rect. Each shoulder fills the corner between the screen edge
// and the body's end, bounded by a quarter circle of radius s.
function shoulderPath(s, g) {
  if (!(s > 0)) return ""
  var h = g.edge === "top" || g.edge === "bottom"
  var n = g.edge === "top" ? [0, 1] : g.edge === "bottom" ? [0, -1]
        : g.edge === "left" ? [1, 0] : [-1, 0]
  var ex = g.edge === "right" ? g.x + g.w : g.x
  var ey = g.edge === "bottom" ? g.y + g.h : g.y
  var corners = h
    ? [{ c: [g.x, ey], u: [-1, 0] }, { c: [g.x + g.w, ey], u: [1, 0] }]
    : [{ c: [ex, g.y], u: [0, -1] }, { c: [ex, g.y + g.h], u: [0, 1] }]
  return corners.map(function(k) {
    var c = k.c, u = k.u
    var sweep = (u[0] * n[1] - u[1] * n[0]) < 0 ? 0 : 1
    return "M " + (c[0] + u[0] * s) + " " + (c[1] + u[1] * s)
      + " L " + c[0] + " " + c[1]
      + " L " + (c[0] + n[0] * s) + " " + (c[1] + n[1] * s)
      + " A " + s + " " + s + " 0 0 " + sweep + " "
      + (c[0] + u[0] * s) + " " + (c[1] + u[1] * s) + " Z"
  }).join(" ")
}
