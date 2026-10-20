// Gate test: node tests/launcher/calc.test.mjs
import assert from "node:assert/strict"
import { load } from "./load.mjs"
const { evaluate } = load("Calc.js", ["evaluate"])
const show = (s) => { const r = evaluate(s); return r ? r.display : null }

// arithmetic and precedence
assert.equal(show("1+2*3"), "7")
assert.equal(show("(1+2)*3"), "9")
assert.equal(show("2^3^2"), "512", "power is right associative")
assert.equal(show("-2^2"), "4", "unary minus binds tighter, like a pocket calculator")
assert.equal(show("10/4"), "2.5")
assert.equal(show("10 mod 3"), "1")
assert.equal(show("2 ** 10"), "1024")
assert.equal(show("6 × 7"), "42")
assert.equal(show("0.1+0.2"), "0.3", "binary noise is hidden")
assert.equal(show("1/3"), "0.333333333333")
assert.equal(show("1e3 + 1"), "1001")

// percent forms
assert.equal(show("100 + 10%"), "110")
assert.equal(show("100 - 10%"), "90")
assert.equal(show("20% of 150"), "30")
assert.equal(show("50%*4"), "2")

// functions and constants
assert.equal(show("sqrt(16)"), "4")
assert.equal(show("2*pi"), "6.28318530718")
assert.equal(show("log2(8)"), "3")
assert.equal(show("round(2.6)"), "3")

// unit conversion
assert.equal(show("5 km to mi"), "3.10685596119 mi")
assert.equal(show("100 f to c"), "37.7777777778 c")
assert.equal(show("0 c in k"), "273.15 k")
assert.equal(show("1 gb to mb"), "1000 mb")
assert.equal(show("2 h to min"), "120 min")
assert.equal(show("(2+3) kg to lb"), "11.0231131092 lb")
assert.equal(show("5 km to kg"), null, "different categories do not convert")

// not a calculation: these must fall through to app search
for (const s of ["", "   ", "firefox", "5", "pi", "e", "kitty 2", "1+", "(1+2", "sqrt", "sqrt 4", "2 +* 3", "1,000", "abc+1"]) {
  assert.equal(evaluate(s), null, "should not evaluate: " + JSON.stringify(s))
}
assert.equal(evaluate("1/0"), null, "infinity is not an answer")
assert.equal(evaluate("0/0"), null)
assert.equal(evaluate("x".repeat(300)), null)
assert.equal(show("10^20"), "1e+20")
assert.equal(show("1/1000000000"), "1e-9")
// no eval path: identifiers that look like code stay inert
assert.equal(evaluate("process.exit()"), null)
assert.equal(evaluate("constructor+1"), null)
assert.equal(evaluate("__proto__*2"), null)

const r = evaluate("2+2")
assert.equal(r.copy, "4")
assert.equal(r.expression, "2+2")
console.log("calc: ok")
