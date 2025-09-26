/***************************************************************************
 *   Copyright (C) 2015 by Eike Hein <hein@kde.org>                        *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          *
 *                                                                         *
 *   You should have received a copy of the GNU General Public License     *
 *   along with this program; if not, write to the                         *
 *   51 Franklin Street, Fifth Floor, Boston, MA  02110-1301  USA .        *
 ***************************************************************************/

import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami

import "code/tools.js" as Tools

Item {
    id: item

    // FORCE SQUARE DIMENSIONS
    width: GridView.view.cellWidth
    height: GridView.view.cellWidth  // Force height = width for perfect squares

    enabled: !model.disabled

    property bool showLabel: true
    property int itemIndex: model.index
    property string favoriteId: model.favoriteId !== undefined ? model.favoriteId : ""
    property url url: model.url !== undefined ? model.url : ""
    property var m: model

    // --- category / subfolder support ---
    readonly property bool isDirectory: model.hasChildren ?? false
    readonly property var directoryModel: isDirectory ? GridView.view.model.modelForRow(itemIndex) : undefined

    property bool hasActionList: ((model.favoriteId !== null)
    || (("hasActionList" in model) && (model.hasActionList === true)))

    // --- hover/focus state for rainbow highlight ---
    property bool isHovered: mouseArea.containsMouse
    property bool isFocused: item.GridView.isCurrentItem
    property bool isHighlighted: isHovered || isFocused

    Accessible.role: Accessible.MenuItem
    Accessible.name: model.display

    function openActionMenu(x, y) {
        var actionList = hasActionList ? model.actionList : [];
        Tools.fillActionMenu(i18n, actionMenu, actionList, GridView.view.model.favoritesModel, model.favoriteId);
        actionMenu.visualParent = item;
        actionMenu.open(x, y);
    }

    function actionTriggered(actionId, actionArgument) {
        var close = (Tools.triggerAction(GridView.view.model, model.index, actionId, actionArgument) === true);
        if (close) {
            kicker.toggle();
        }
    }

    // --- MAIN DELEGATE BOX (transparent by default) ---
    Rectangle {
        id: delegateBox
        anchors.fill: parent
        anchors.margins: 6
        radius: 16

        // Calculate dimensions
        property int boxSize: Math.min(width, height)
        property int iconAreaSize: Math.floor(boxSize * 0.65)  // 65% for icon area
        property int labelHeight: showLabel ? Math.floor(boxSize * 0.25) : 0  // 25% for label
        property int spacing: Math.floor(boxSize * 0.05)  // 5% spacing

        // Transparent background by default
        color: "transparent"
        border.width: 0

        // --- HIGHLIGHT BACKGROUND + RAINBOW BORDER (only visible on hover/focus) ---
        Rectangle {
            id: highlightBox
            anchors.fill: parent
            radius: parent.radius

            // Only visible when item is hovered or focused
            visible: item.isHighlighted
            opacity: visible ? 1.0 : 0.0

            // Smooth fade transition
            Behavior on opacity {
                NumberAnimation { duration: 200; easing.type: Easing.OutCubic }
            }

            // Gray background that appears on hover/focus
            color: Qt.rgba(0.1, 0.1, 0.1, 0.3)

            // Animated rainbow border
            border.width: 4
            property real hueOffset: 0
            border.color: Qt.hsla(hueOffset / 360, 1.0, 0.6, 1.0)

            // Rainbow animation - only runs when visible
            NumberAnimation on hueOffset {
                running: highlightBox.visible
                from: 0
                to: 360
                duration: 2000
                loops: Animation.Infinite
                easing.type: Easing.Linear
            }
        }
        Column {
            id: contentColumn
            anchors.centerIn: parent
            width: parent.boxSize - 20  // Leave margin for border
            spacing: delegateBox.spacing

            // --- SINGLE ICON AREA ---
            Item {
                id: iconArea
                width: parent.width
                height: delegateBox.iconAreaSize
                anchors.horizontalCenter: parent.horizontalCenter

                // --- CATEGORY PREVIEW (single 2x2 grid) ---
                Rectangle {
                    id: categoryPreviewBox
                    visible: isDirectory && directoryModel && directoryModel.count > 0
                    anchors.centerIn: parent
                    width: parent.height * 0.9
                    height: width
                    radius: 8
                    color: Qt.rgba(0.4, 0.4, 0.4, 0.3)
                    border.width: 1
                    border.color: Qt.rgba(0.4, 0.4, 0.5, 0.6)

                    // Single 2x2 Preview Grid
                    Grid {
                        id: miniIconGrid
                        anchors.centerIn: parent
                        width: parent.width - 8
                        height: parent.height - 8
                        rows: 2
                        columns: 2
                        spacing: 2

                        Repeater {
                            model: Math.min(4, directoryModel ? directoryModel.count : 0)
                            delegate: Item {
                                width: (miniIconGrid.width - miniIconGrid.spacing) / 2
                                height: (miniIconGrid.height - miniIconGrid.spacing) / 2

                                Kirigami.Icon {
                                    anchors.centerIn: parent
                                    width: parent.width * 0.8
                                    height: parent.height * 0.8
                                    source: {
                                        if (directoryModel && index < directoryModel.count) {
                                            return directoryModel.data(directoryModel.index(index, 0), Qt.DecorationRole) || "application-x-executable"
                                        }
                                        return "application-x-executable"
                                    }
                                    animated: false
                                    roundToIconSize: false
                                }
                            }
                        }
                    }
                }

                // --- REGULAR APP ICON (single large icon) ---
                Rectangle {
                    id: regularAppIcon
                    visible: !isDirectory
                    anchors.centerIn: parent
                    width: parent.height * 0.85
                    height: width
                    radius: 8
                    color: Qt.rgba(0.9, 0.9, 0.9, 0.1)

                    Kirigami.Icon {
                        anchors.centerIn: parent
                        width: parent.width
                        height: parent.height
                        source: model.decoration || "application-x-executable"
                        animated: false
                        roundToIconSize: false
                    }
                }
            }

            // --- SINGLE LABEL AREA ---
            Rectangle {
                id: labelBox
                visible: showLabel
                width: parent.width  // Full width of content column
                height: delegateBox.labelHeight
                anchors.horizontalCenter: parent.horizontalCenter
                radius: 4

                // Different styling for categories vs regular apps
                color: isDirectory ?
                Qt.rgba(0.2, 0.4, 0.8, 0.85) :  // Blue for categories
                Qt.rgba(0.9, 0.9, 0.9, 0.9)     // Light gray for regular apps

                border.width: 1
                border.color: isDirectory ?
                Qt.rgba(0.3, 0.5, 1.0, 0.7) :   // Light blue border for categories
                Qt.rgba(0.5, 0.5, 0.5, 0.5)     // Gray border for regular apps

                PC3.Label {
                    id: appLabel
                    anchors.fill: parent
                    anchors.margins: 3

                    text: model.display || ""
                    color: isDirectory ? "#FFFFFF" : "#000000"
                    font.weight: Font.Medium
                    font.pointSize: Math.max(7, Math.min(10, delegateBox.boxSize / 12))

                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    wrapMode: Text.NoWrap
                    elide: Text.ElideRight
                    clip: true
                }
            }
        }
    }

    // --- TOOLTIP ---
    PlasmaCore.ToolTipArea {
        id: toolTip
        property string text: model.display || ""
        anchors.fill: parent
        active: kicker.visible && appLabel.truncated
        mainItem: toolTipDelegate
        onContainsMouseChanged: item.GridView.view.itemContainsMouseChanged(containsMouse)
    }

    // --- KEY HANDLING ---
    Keys.onPressed: event => {
        if (event.key === Qt.Key_Menu && hasActionList) {
            event.accepted = true;
            openActionMenu(item);
        } else if ((event.key === Qt.Key_Enter || event.key === Qt.Key_Return)) {
            event.accepted = true;
            if ("trigger" in GridView.view.model) {
                if (isDirectory) {
                    // Enter category/folder
                    if (GridView.view.enterDirectory) {
                        GridView.view.enterDirectory(itemIndex);
                    } else if (GridView.view.trigger) {
                        GridView.view.trigger(itemIndex);
                    }
                } else {
                    // Launch regular app
                    GridView.view.model.trigger(itemIndex, "", null);
                    kicker.toggle();
                }
            }
        }
    }

    // --- MOUSE HANDLING ---
    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true

        onClicked: {
            if (isDirectory) {
                // Enter category/folder
                if (GridView.view.enterDirectory) {
                    GridView.view.enterDirectory(itemIndex)
                } else if (GridView.view.trigger) {
                    GridView.view.trigger(itemIndex)
                }
            } else {
                // Launch regular app
                if ("trigger" in GridView.view.model) {
                    GridView.view.model.trigger(itemIndex, "", null)
                    kicker.toggle()
                }
            }
        }

        onEntered: {
            item.GridView.view.currentIndex = itemIndex
        }
    }
}
