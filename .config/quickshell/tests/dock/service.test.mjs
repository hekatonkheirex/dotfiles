// Gate test: node tests/dock/service.test.mjs
import { readFileSync } from "node:fs"
import { fileURLToPath } from "node:url"
import assert from "node:assert/strict"

const rd = p => readFileSync(fileURLToPath(new URL(p, import.meta.url)), "utf8")
const qmldir = rd("../../config/qmldir")
assert.match(qmldir, /singleton WindowService 1\.0 WindowService\.qml/, "registered singleton")
const svc = rd("../../config/WindowService.qml")
assert.match(svc, /pragma Singleton/)
assert.match(svc, /import "WindowState\.js" as WindowState/)
assert.match(svc, /niri msg -j event-stream/, "reads the event stream")
assert.match(svc, /NIRI_SOCKET=\$\(ls -t \/run\/user\/\$\(id -u\)\/niri\.\*\.sock/, "socket discovery wrapper")
assert.match(svc, /running: Config\.elenaTheme/, "only runs under elena")
assert.match(svc, /WindowState\.applyEvent\(/, "folds events through the reducer")
assert.match(svc, /JSON\.parse\(/, "parses lines")
assert.match(svc, /try \{[\s\S]*JSON\.parse[\s\S]*\} catch/, "tolerates bad lines")

// The stream Process itself: bound to elena, feeds the reducer, resets on stop.
const proc = svc.match(/property Process stream: Process \{[\s\S]*?\n  \}\n/)
assert.ok(proc, "stream Process block present")
assert.match(proc[0], /running: Config\.elenaTheme/, "Process.running bound to elenaTheme")
assert.match(proc[0], /stdout: SplitParser \{[\s\S]*root\.feed\(/, "stdout parser calls root.feed")
assert.match(proc[0], /onRunningChanged:[\s\S]*WindowState\.empty\(\)/, "state resets when the stream stops")
assert.match(proc[0], /if \(Config\.elenaTheme\) \{[\s\S]*retry\.restart\(\)/, "retry scheduled only while elena")
assert.match(proc[0], /running: Config\.elenaTheme && !root\.backoff/, "restart goes through the binding, not an assignment")
assert.doesNotMatch(svc, /stream\.running\s*=/, "never assign running imperatively")
console.log("window service: ok")
