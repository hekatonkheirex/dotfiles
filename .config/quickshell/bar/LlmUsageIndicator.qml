import QtQuick
import QtQml
import "primitives"
import "../config"

StatusIndicator {
  id: root

  function summary(name, service) {
    return name + " · "
      + (service.fiveHour ? "5h: " + Math.round(service.fiveHour.used_percent) + "% used" : "5h unavailable")
      + " · " + (service.weekly ? "Weekly: " + Math.round(service.weekly.used_percent) + "% used" : "Weekly unavailable")
      + (service.stale ? " · Stale reading" : "")
      + (service.status === "error" ? " · " + service.statusMessage : "")
  }

  iconComponent: Component {
    LlmUsageIcon { ink: root.iconColor }
  }
  loading: CodexUsageService.loading && ClaudeUsageService.loading
    && !CodexUsageService.fiveHour && !CodexUsageService.weekly
    && !ClaudeUsageService.fiveHour && !ClaudeUsageService.weekly
  badgeText: CodexUsageService.stale || ClaudeUsageService.stale
    || CodexUsageService.status === "error" || ClaudeUsageService.status === "error" ? "!" : ""
  accessibleName: "LLM usage"
  accessibleDescription: root.summary("Codex", CodexUsageService) + "\n"
    + root.summary("Claude", ClaudeUsageService)
  tooltipText: accessibleDescription

  Binding {
    target: CodexUsageService
    property: "indicatorActive"
    value: root.visible
  }
  Binding {
    target: ClaudeUsageService
    property: "indicatorActive"
    value: root.visible
  }
}
