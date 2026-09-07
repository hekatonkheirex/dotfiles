import QtQuick

import Quickshell
import Quickshell.Services.Notifications

Item {
    id: root

    property var settings
    property alias notifications: notificationServer.trackedNotifications
    readonly property int notificationCount: notificationServer.trackedNotifications.values.length
    readonly property bool enabled: settings ? settings.notificationsEnabled : true
    readonly property bool doNotDisturb: settings ? settings.notificationsDoNotDisturb : false
    readonly property real toastDurationSeconds: settings ? settings.notificationToastDuration : 5.0
    readonly property bool toastVisible: root.currentToast !== null
        && root.enabled
        && !root.doNotDisturb

    property int unreadCount: 0
    property var unreadIds: ({})
    property var currentToast: null

    signal notificationReceived(var notification)

    function notificationKey(notification) {
        return notification ? String(notification.id) : "";
    }

    function copyMap(source) {
        var result = {};
        for (var key in source) {
            if (source.hasOwnProperty(key)) {
                result[key] = source[key];
            }
        }
        return result;
    }

    function markUnread(notification) {
        var key = root.notificationKey(notification);
        if (key.length === 0 || root.unreadIds[key]) {
            return;
        }

        var next = root.copyMap(root.unreadIds);
        next[key] = true;
        root.unreadIds = next;
        root.unreadCount += 1;
    }

    function markRead(notification) {
        var key = root.notificationKey(notification);
        if (key.length === 0 || !root.unreadIds[key]) {
            return;
        }

        var next = root.copyMap(root.unreadIds);
        delete next[key];
        root.unreadIds = next;
        root.unreadCount = Math.max(0, root.unreadCount - 1);
    }

    function markAllRead() {
        root.unreadIds = {};
        root.unreadCount = 0;
    }

    function pruneUnread() {
        var active = {};
        var values = notificationServer.trackedNotifications.values;
        for (var index = 0; index < values.length; index++) {
            active[root.notificationKey(values[index])] = true;
        }

        var next = {};
        var count = 0;
        for (var key in root.unreadIds) {
            if (root.unreadIds.hasOwnProperty(key) && active[key]) {
                next[key] = true;
                count += 1;
            }
        }
        root.unreadIds = next;
        root.unreadCount = count;
    }

    function receive(notification) {
        if (!notification) {
            return;
        }

        if (!root.enabled) {
            notification.dismiss();
            return;
        }

        notification.tracked = true;
        if (!notification.lastGeneration) {
            root.markUnread(notification);
            root.currentToast = notification;
            toastTimer.restart();
            root.notificationReceived(notification);
        }
    }

    function dismiss(notification) {
        if (!notification) {
            return;
        }
        root.markRead(notification);
        if (root.currentToast === notification) {
            root.closeToast();
        }
        notification.dismiss();
    }

    function invokeAction(notification, action) {
        if (!notification || !action) {
            return;
        }
        root.markRead(notification);
        action.invoke();
        if (root.currentToast === notification) {
            root.closeToast();
        }
    }

    function clearAll() {
        var values = notificationServer.trackedNotifications.values.slice();
        for (var index = 0; index < values.length; index++) {
            values[index].dismiss();
        }
        root.markAllRead();
        root.closeToast();
    }

    function closeToast() {
        root.currentToast = null;
        toastTimer.stop();
    }

    function toggleDoNotDisturb() {
        if (root.settings) {
            root.settings.notificationsDoNotDisturb = !root.settings.notificationsDoNotDisturb;
        }
    }

    NotificationServer {
        id: notificationServer

        keepOnReload: true
        persistenceSupported: true
        bodySupported: true
        bodyMarkupSupported: false
        bodyHyperlinksSupported: false
        bodyImagesSupported: false
        imageSupported: true
        actionsSupported: true
        actionIconsSupported: false
        inlineReplySupported: false

        onNotification: function(notification) {
            root.receive(notification);
        }
    }

    Connections {
        target: notificationServer.trackedNotifications

        function onObjectRemovedPost(object) {
            if (root.currentToast === object) {
                root.closeToast();
            }
            root.pruneUnread();
        }
    }

    Timer {
        id: toastTimer
        interval: Math.max(1000, Math.round(root.toastDurationSeconds * 1000))
        repeat: false
        onTriggered: root.closeToast()
    }

    onDoNotDisturbChanged: if (root.doNotDisturb) root.closeToast()
    onEnabledChanged: if (!root.enabled) root.closeToast()
}
