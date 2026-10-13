import QtQuick
import "../../config"
import "../primitives"

// Sidebar search box. Submitting hands the text to the launcher (shell.qml);
// results are never shown here.
TextFieldControl {
  id: root

  signal submitted(string text)
  signal escaped()

  placeholder: "Search"
  leadingIcon: "search"
  accessibleName: "Search apps and actions"

  function focusField() { root.input.forceActiveFocus() }
  function clear() { root.text = "" }

  onAccepted: root.submitted(root.text)
  onEscapePressed: root.escaped()
}
