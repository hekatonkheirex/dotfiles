.pragma library

// Matugen accent roles a user may shortlist. Stored by role name so the
// picks follow wallpaper and light/dark changes. `on` is the paired
// foreground that replaces fgPrimary when the role becomes the accent.
var ROLES = [
  { key: "primary", on: "on_primary", label: "Primary" },
  { key: "primary_container", on: "on_primary_container", label: "Primary container" },
  { key: "primary_fixed", on: "on_primary_fixed", label: "Primary fixed" },
  { key: "primary_fixed_dim", on: "on_primary_fixed", label: "Primary fixed dim" },
  { key: "secondary", on: "on_secondary", label: "Secondary" },
  { key: "secondary_container", on: "on_secondary_container", label: "Secondary container" },
  { key: "secondary_fixed", on: "on_secondary_fixed", label: "Secondary fixed" },
  { key: "secondary_fixed_dim", on: "on_secondary_fixed", label: "Secondary fixed dim" },
  { key: "tertiary", on: "on_tertiary", label: "Tertiary" },
  { key: "tertiary_container", on: "on_tertiary_container", label: "Tertiary container" },
  { key: "tertiary_fixed", on: "on_tertiary_fixed", label: "Tertiary fixed" },
  { key: "tertiary_fixed_dim", on: "on_tertiary_fixed", label: "Tertiary fixed dim" }
]
var MAX = 8

function find(key) {
  for (var i = 0; i < ROLES.length; i++) if (ROLES[i].key === key) return ROLES[i]
  return null
}

// "a,b,c" -> unique, valid role keys, at most MAX.
function normalize(csv) {
  var out = []
  var parts = String(csv || "").split(",")
  for (var i = 0; i < parts.length && out.length < MAX; i++) {
    var key = parts[i].trim()
    if (find(key) && out.indexOf(key) < 0) out.push(key)
  }
  return out
}

// Toggle membership; adding past MAX is a no-op. Returns the new csv.
function toggle(csv, key) {
  var list = normalize(csv)
  var at = list.indexOf(key)
  if (at >= 0) list.splice(at, 1)
  else if (find(key) && list.length < MAX) list.push(key)
  return list.join(",")
}

// The active role, or "" when it is unset or no longer in the shortlist.
function resolve(csv, active) {
  return normalize(csv).indexOf(active) >= 0 ? active : ""
}

function onRole(key) {
  var role = find(key)
  return role ? role.on : "on_primary"
}
