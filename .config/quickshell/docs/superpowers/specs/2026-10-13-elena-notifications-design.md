# Elena notification presentation redesign

## Objective and ownership
Apply the existing Elenapan dashed-card and tracked-monospace grammar to bar/NotificationPopup.qml history and bar/NotificationToast.qml toasts. Use the already shared primitives/DashedFrame.qml. The notification server, shell DND/quiet-hours routing, tracking and component lifecycle functions remain unchanged.

## Presentation
- History: dark rounded surface, dashed outline, uppercase monospace heading/count, app metadata and timestamp; regular-case summary/body text and existing action buttons. Keep existing history ordering and clear/remove controls.
- Toast: matching dark dashed card, uppercase monospace app metadata and NOW status. Critical notifications retain their solid error-colored border and error avatar, with an explicit CRITICAL text cue rather than relying only on color.
- Preserve existing dimensions, placement, body formatting/elision, action labels, accessibility, native buttons and motion settings. No new polling, model fields, queue rules, notification providers or dependencies.
- History alone overrides its PopupBase border declaratively; other popups keep their framing. Frames repaint only on geometry/color/show changes.

## Preserved behavior
Notification delivery and close signals; default and named actions; dismiss versus toast timeout; persistent/critical held notification behavior; DND with optional critical bypass; quiet hours; closed notifications retained in history without live actions; history limits and tracking release. Do not send private clipboard contents or execute application-defined actions on the live desktop. No real power or lock actions.

## Verification
Use a private session D-Bus with an actual Quickshell NotificationServer and real notify-send/gdbus calls. Prove delivery to history and toast, normal timeout keeping history, persistent/critical behavior, close/removal, DND suppression with retained history and critical bypass. Exercise default/named actions with a private notification client and observe its action return, not a mocked forwarding echo. Capture and inspect normal/critical toast, populated/empty history and long-body layouts. Native QML context can inspect actual component state through throwaway injected probes; no production IPC is added for tests.

Run `bash scripts/m3-qmllint-gate.sh`, `bash scripts/controls-behavior.sh`, existing Node regressions and `bash scripts/style-refs.sh --elena`. Update README/handoff after smoke proof. Live validation follows a user cold restart. The user authorized commit/push of completed work before this stage; notification work remains separate unless publication is requested again.

## Runtime-discovered correction
The named toast action handler must capture the toast owner before `invoke()`.
A real sender's action can synchronously close the notification and destroy its
button delegate; looking up the enclosing root afterward produced a
ReferenceError in the failing-before smoke. The captured owner preserves the
existing clearCurrent behavior, and the passing-after real D-Bus run clears
the runtime error gate.
