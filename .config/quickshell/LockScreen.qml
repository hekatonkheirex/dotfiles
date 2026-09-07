import QtQuick

import Quickshell
import Quickshell.Services.Pam
import Quickshell.Wayland

Item {
    id: root

    readonly property string username: {
        var user = Quickshell.env("USER");
        return user && user.length > 0 ? user : "User";
    }
    readonly property string avatarSource: {
        var home = Quickshell.env("HOME");
        return home && home.length > 0 ? "file://" + home + "/.face.icon" : "";
    }
    readonly property bool locked: sessionLock.locked
    readonly property bool authenticating: pam.active

    property string statusMessage: "Enter your password"
    property bool statusIsError: false
    property string pendingPassword: ""
    property bool lockRequestPending: false

    signal authenticationResult(bool success)

    function lock() {
        if (root.lockRequestPending || sessionLock.locked) {
            return;
        }

        root.lockRequestPending = true;
        if (pam.active) {
            pam.abort();
        }

        root.pendingPassword = "";
        root.statusMessage = "Enter your password";
        root.statusIsError = false;
        sessionLock.locked = true;
        lockRequestTimeout.restart();
    }

    function authenticate(password) {
        if (!sessionLock.locked || pam.active || !password || password.length === 0) {
            return;
        }

        root.pendingPassword = password;
        root.statusMessage = "Checking password...";
        root.statusIsError = false;

        if (!pam.start()) {
            root.pendingPassword = "";
            root.statusMessage = "Authentication is unavailable";
            root.statusIsError = true;
            root.authenticationResult(false);
        }
    }

    PamContext {
        id: pam
        config: "login"

        onResponseRequiredChanged: {
            if (pam.responseRequired && root.pendingPassword.length > 0) {
                pam.respond(root.pendingPassword);
            }
        }

        onPamMessage: function() {
            if (pam.messageIsError) {
                root.statusMessage = "Authentication failed";
                root.statusIsError = true;
            }
        }

        onCompleted: function(result) {
            var success = result === PamResult.Success;
            root.pendingPassword = "";

            if (success) {
                root.statusMessage = "";
                root.statusIsError = false;
                sessionLock.locked = false;
                root.authenticationResult(true);
                return;
            }

            root.statusMessage = result === PamResult.MaxTries
                ? "Too many attempts. Try again later"
                : "Incorrect password";
            root.statusIsError = true;
            root.authenticationResult(false);
        }

        onError: function() {
            root.pendingPassword = "";
            root.statusMessage = "Authentication is unavailable";
            root.statusIsError = true;
            root.authenticationResult(false);
        }
    }

    Connections {
        target: sessionLock

        function onLockedChanged() {
            root.lockRequestPending = false;
        }
    }

    Timer {
        id: lockRequestTimeout
        interval: 5000
        repeat: false

        onTriggered: {
            if (!sessionLock.locked) {
                root.lockRequestPending = false;
            }
        }
    }

    WlSessionLock {
        id: sessionLock

        surface: Component {
            LockScreenSurface {
                controller: root
            }
        }
    }
}
