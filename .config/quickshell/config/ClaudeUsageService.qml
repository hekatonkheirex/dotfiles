pragma Singleton
import QtQml

LlmUsageService {
  providerName: "Claude"
  helperScript: "claude-usage.py"
  pollMinutes: 15
}
