.pragma library

// Launcher calculator: arithmetic, percent forms, functions and unit
// conversion. A hand-written parser, never eval. evaluate() returns
// { value, display, expression } or null when the text is not a calculation.

var CONSTANTS = { pi: Math.PI, e: Math.E, tau: 2 * Math.PI }
var FUNCTIONS = {
  sqrt: Math.sqrt, cbrt: Math.cbrt, abs: Math.abs, round: Math.round,
  floor: Math.floor, ceil: Math.ceil, exp: Math.exp, ln: Math.log,
  log: Math.log10, log10: Math.log10, log2: Math.log2,
  sin: Math.sin, cos: Math.cos, tan: Math.tan,
  asin: Math.asin, acos: Math.acos, atan: Math.atan
}

// factor = size in the category base unit. Temperature is handled apart.
var UNITS = {
  mm: ["length", 0.001], cm: ["length", 0.01], m: ["length", 1], km: ["length", 1000],
  in: ["length", 0.0254], ft: ["length", 0.3048], yd: ["length", 0.9144], mi: ["length", 1609.344],
  mg: ["mass", 0.000001], g: ["mass", 0.001], kg: ["mass", 1], lb: ["mass", 0.45359237], oz: ["mass", 0.028349523125],
  ml: ["volume", 0.001], l: ["volume", 1], gal: ["volume", 3.785411784], cup: ["volume", 0.2365882365],
  b: ["data", 1], kb: ["data", 1e3], mb: ["data", 1e6], gb: ["data", 1e9], tb: ["data", 1e12],
  kib: ["data", 1024], mib: ["data", 1048576], gib: ["data", 1073741824],
  ms: ["time", 0.001], s: ["time", 1], min: ["time", 60], h: ["time", 3600], d: ["time", 86400], wk: ["time", 604800],
  c: ["temp", 0], f: ["temp", 0], k: ["temp", 0]
}

function tokenize(text) {
  var src = text.toLowerCase().replace(/×/g, "*").replace(/÷/g, "/").replace(/−/g, "-").replace(/\*\*/g, "^")
  var re = /\s*(?:(\d+\.?\d*(?:e[+-]?\d+)?|\.\d+(?:e[+-]?\d+)?)|([a-z_][a-z0-9_]*)|([-+*\/^%(),]))/y
  var tokens = []
  var pos = 0
  while (pos < src.length) {
    if (/^\s*$/.test(src.slice(pos))) break
    re.lastIndex = pos
    var m = re.exec(src)
    if (!m) return null
    pos = re.lastIndex
    if (m[1] !== undefined) tokens.push({ t: "num", v: parseFloat(m[1]) })
    else if (m[2] !== undefined) tokens.push({ t: "id", v: m[2] })
    else tokens.push({ t: "op", v: m[3] })
  }
  return tokens
}

// Parse to a value. Percent literals stay { pct: n } until combined so that
// "100 + 10%" means 110 and "20% of 50" means 10.
function parse(tokens) {
  var i = 0
  var sawOperation = false
  function peek() { return tokens[i] }
  function isOp(v) { var k = tokens[i]; return k && k.t === "op" && k.v === v }
  function isId(v) { var k = tokens[i]; return k && k.t === "id" && k.v === v }
  function plain(x) { return typeof x === "object" ? x.pct / 100 : x }

  function expr() {
    var left = term()
    while (isOp("+") || isOp("-")) {
      var op = tokens[i++].v
      var right = term()
      sawOperation = true
      if (typeof right === "object") {
        var base = plain(left)
        left = op === "+" ? base * (1 + right.pct / 100) : base * (1 - right.pct / 100)
      } else {
        left = op === "+" ? plain(left) + right : plain(left) - right
      }
    }
    return left
  }

  function term() {
    var left = power()
    for (;;) {
      if (isOp("*") || isOp("/")) {
        var op = tokens[i++].v
        var right = plain(power())
        sawOperation = true
        left = op === "*" ? plain(left) * right : plain(left) / right
      } else if (isId("mod")) {
        i++
        sawOperation = true
        left = plain(left) % plain(power())
      } else if (isId("of") && typeof left === "object") {
        i++
        sawOperation = true
        left = left.pct / 100 * plain(power())
      } else {
        return left
      }
    }
  }

  function power() {
    var base = unary()
    if (isOp("^")) {
      i++
      sawOperation = true
      return Math.pow(plain(base), plain(power()))
    }
    return base
  }

  function unary() {
    if (isOp("-")) { i++; sawOperation = true; return -plain(unary()) }
    if (isOp("+")) { i++; return unary() }
    return postfix()
  }

  function postfix() {
    var v = primary()
    if (isOp("%") && typeof v === "number") {
      i++
      sawOperation = true
      return { pct: v }
    }
    return v
  }

  function primary() {
    var k = peek()
    if (!k) throw new Error("end")
    if (k.t === "num") { i++; return k.v }
    if (k.t === "op" && k.v === "(") {
      i++
      var inner = expr()
      if (!isOp(")")) throw new Error("paren")
      i++
      sawOperation = true
      return inner
    }
    if (k.t === "id") {
      i++
      if (Object.prototype.hasOwnProperty.call(FUNCTIONS, k.v)) {
        if (!isOp("(")) throw new Error("call")
        i++
        var arg = plain(expr())
        if (!isOp(")")) throw new Error("paren")
        i++
        sawOperation = true
        return FUNCTIONS[k.v](arg)
      }
      if (Object.prototype.hasOwnProperty.call(CONSTANTS, k.v)) return CONSTANTS[k.v]
    }
    throw new Error("token")
  }

  try {
    var result = plain(expr())
    if (i !== tokens.length) return null
    return { value: result, operation: sawOperation }
  } catch (e) {
    return null
  }
}

function formatNumber(n) {
  if (!isFinite(n)) return null
  if (n === 0) return "0"
  var abs = Math.abs(n)
  if (abs >= 1e15 || abs < 1e-6) return n.toExponential(6).replace(/\.?0+e/, "e")
  // 12 significant digits hides binary noise such as 0.1 + 0.2.
  return String(parseFloat(n.toPrecision(12)))
}

function convertTemperature(v, from, to) {
  var c = from === "c" ? v : (from === "f" ? (v - 32) * 5 / 9 : v - 273.15)
  return to === "c" ? c : (to === "f" ? c * 9 / 5 + 32 : c + 273.15)
}

function convert(value, from, to) {
  var a = UNITS[from]
  var b = UNITS[to]
  if (!a || !b || a[0] !== b[0]) return null
  if (a[0] === "temp") return convertTemperature(value, from, to)
  return value * a[1] / b[1]
}

function evaluate(text) {
  var raw = String(text || "").trim()
  if (raw === "" || raw.length > 200) return null

  var conv = /^(.+?)\s*([a-z]+)\s+(?:to|in|as)\s+([a-z]+)$/i.exec(raw)
  if (conv) {
    var from = conv[2].toLowerCase()
    var to = conv[3].toLowerCase()
    var tokens0 = tokenize(conv[1])
    var amount = tokens0 && tokens0.length ? parse(tokens0) : null
    if (amount && UNITS[from] && UNITS[to]) {
      var out = convert(amount.value, from, to)
      var shown = out === null ? null : formatNumber(out)
      if (shown === null) return null
      return { value: out, display: shown + " " + to, copy: shown, expression: conv[1].trim() + " " + from + " → " + to }
    }
  }

  var tokens = tokenize(raw)
  if (!tokens || tokens.length === 0) return null
  var parsed = parse(tokens)
  if (!parsed || !parsed.operation) return null
  var display = formatNumber(parsed.value)
  if (display === null) return null
  return { value: parsed.value, display: display, copy: display, expression: raw }
}
