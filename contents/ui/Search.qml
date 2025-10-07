import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.core as PlasmaCore
import org.kde.kirigami 2.20 as Kirigami

Item {
    id: searchComponent

    property alias searchField: searchInput
    property bool hasResults: runnerModel ? runnerModel.count > 0 : false

    property bool allAppsActive: false
    property bool favoritesActive: false

    signal allAppsToggled()
    signal favoritesToggled()

    implicitHeight: 40

    RowLayout {
        anchors.fill: parent
        spacing: 8

        // Main search container
        Rectangle {
            id: searchContainer
            Layout.fillWidth: true
            Layout.fillHeight: true
            Layout.maximumHeight: 40
            radius: 20
            color: "white"
            border.width: 1
            border.color: searchInput.activeFocus ? Kirigami.Theme.highlightColor : Qt.rgba(0, 0, 0, 0.2)

            Behavior on border.color {
                ColorAnimation { duration: 200 }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 8

                Kirigami.Icon {
                    id: searchIcon
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    source: "search"
                    color: Qt.rgba(0, 0, 0, 0.5)
                }

                PC3.TextField {
                    id: searchInput
                    Layout.fillWidth: true
                    Layout.fillHeight: true

                    placeholderText: i18n("Type here to search...")
                    cursorVisible: activeFocus
                    selectByMouse: true

                    background: Rectangle {
                        color: "transparent"
                    }

                    color: "black"
                    font.pointSize: 10
                    font.weight: Font.Normal

                    onTextChanged: {
                        var query = text.trim();
                        var isSearching = (query.length > 0);
                        if (kicker.searching !== isSearching) {
                            kicker.searching = isSearching;
                        }

                        if (isSearching) {
                            searchUpdateTimer.restart();
                        } else {
                            searchUpdateTimer.stop();
                            if (runnerModel) {
                                runnerModel.query = "";
                            }
                        }
                    }

                    Timer {
                        id: searchUpdateTimer
                        interval: 300
                        repeat: false
                        onTriggered: {
                            var query = searchInput.text.trim();
                            if (typeof runnerModel !== "undefined" && runnerModel) {
                                runnerModel.query = query;
                            }
                        }
                    }

                    Keys.onPressed: function(event) {
                        if (event.key === Qt.Key_Down) {
                            event.accepted = true;
                            if (kicker.searching && searchGrid && searchGrid.visible) {
                                searchGrid.forceActiveFocus();
                                searchGrid.selectFirst();
                            } else {
                                if (rootItem.showCategorizedApps && categoryGrid) {
                                    categoryGrid.forceActiveFocus();
                                } else if (globalFavoritesGrid && globalFavoritesGrid.visible) {
                                    globalFavoritesGrid.forceActiveFocus();
                                }
                            }
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            event.accepted = true;
                            if (kicker.searching && searchGrid && searchGrid.visible) {
                                searchGrid.triggerSelected();
                            }
                        } else if (event.key === Qt.Key_Escape) {
                            event.accepted = true;
                            if (text.length > 0) {
                                clearSearch();
                            } else {
                                kicker.expanded = false;
                            }
                        }
                    }

                    onActiveFocusChanged: {
                        if (activeFocus) {
                            selectAll();
                        }
                    }
                }

                PC3.ToolButton {
                    id: clearButton
                    Layout.preferredWidth: 24
                    Layout.preferredHeight: 24
                    visible: searchInput.text.length > 0
                    opacity: visible ? 1.0 : 0.0

                    icon.name: "edit-clear"
                    icon.width: 16
                    icon.height: 16

                    Behavior on opacity {
                        NumberAnimation { duration: 150 }
                    }

                    onClicked: {
                        clearSearch();
                        searchInput.forceActiveFocus();
                    }
                }
            }
        }

        // Star button (Favorites) - FIXED
        PC3.ToolButton {
            id: favoritesButton
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40

            checkable: true
            checked: searchComponent.favoritesActive
            hoverEnabled: true

            icon.name: checked ? "starred-symbolic" : "non-starred-symbolic"
            icon.width: 24
            icon.height: 24
            icon.color: checked ? Kirigami.Theme.highlightColor : Qt.rgba(0, 0, 0, 0.6)

            background: Rectangle {
                radius: 8
                color: favoritesButton.checked ?
                Qt.rgba(Kirigami.Theme.highlightColor.r,
                        Kirigami.Theme.highlightColor.g,
                        Kirigami.Theme.highlightColor.b, 0.15) :
                        favoritesButton.hovered ?
                        Qt.rgba(0, 0, 0, 0.05) :
                        "transparent"

                        Behavior on color { ColorAnimation { duration: 150 } }
            }

            onClicked: {
                console.log("FAVORITES BUTTON CLICKED");
                searchComponent.favoritesToggled();
            }

            // FIXED: Visible tooltip with black text
            PC3.ToolTip {
                text: i18n("Favorites")
                visible: parent.hovered
                delay: 500

                // Make tooltip visible with dark text
                contentItem: PC3.Label {
                    text: i18n("Favorites")
                    color: "black"
                }

                background: Rectangle {
                    color: "white"
                    border.color: Qt.rgba(0, 0, 0, 0.2)
                    border.width: 1
                    radius: 4
                }
            }
        }

        // Grid button (All Apps) - Windows logo style
        PC3.ToolButton {
            id: allAppsButton
            Layout.preferredWidth: 40
            Layout.preferredHeight: 40

            checkable: true
            checked: searchComponent.allAppsActive

            contentItem: Item {
                implicitWidth: 20
                implicitHeight: 20

                // Windows logo: 4 squares in 2x2 grid
                Column {
                    anchors.centerIn: parent
                    spacing: 3

                    Row {
                        spacing: 3
                        Rectangle {
                            width: 7
                            height: 7
                            radius: 1
                            color: allAppsButton.checked ?
                            Kirigami.Theme.highlightColor :
                            Qt.rgba(0, 0, 0, 0.6)
                            opacity: allAppsButton.hovered || allAppsButton.checked ? 1.0 : 0.7

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                        Rectangle {
                            width: 7
                            height: 7
                            radius: 1
                            color: allAppsButton.checked ?
                            Kirigami.Theme.highlightColor :
                            Qt.rgba(0, 0, 0, 0.6)
                            opacity: allAppsButton.hovered || allAppsButton.checked ? 1.0 : 0.7

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }

                    Row {
                        spacing: 3
                        Rectangle {
                            width: 7
                            height: 7
                            radius: 1
                            color: allAppsButton.checked ?
                            Kirigami.Theme.highlightColor :
                            Qt.rgba(0, 0, 0, 0.6)
                            opacity: allAppsButton.hovered || allAppsButton.checked ? 1.0 : 0.7

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                        Rectangle {
                            width: 7
                            height: 7
                            radius: 1
                            color: allAppsButton.checked ?
                            Kirigami.Theme.highlightColor :
                            Qt.rgba(0, 0, 0, 0.6)
                            opacity: allAppsButton.hovered || allAppsButton.checked ? 1.0 : 0.7

                            Behavior on color { ColorAnimation { duration: 150 } }
                            Behavior on opacity { NumberAnimation { duration: 150 } }
                        }
                    }
                }
            }

            background: Rectangle {
                radius: 8
                color: allAppsButton.checked ?
                Qt.rgba(Kirigami.Theme.highlightColor.r,
                        Kirigami.Theme.highlightColor.g,
                        Kirigami.Theme.highlightColor.b, 0.15) :
                        allAppsButton.hovered ?
                        Qt.rgba(0, 0, 0, 0.05) :
                        "transparent"

                        Behavior on color { ColorAnimation { duration: 150 } }
            }

            onClicked: {
                console.log("ALL APPS BUTTON CLICKED");
                searchComponent.allAppsToggled();
            }

            // FIXED: Visible tooltip with black text
            PC3.ToolTip {
                text: i18n("All Applications")
                visible: parent.hovered
                delay: 500

                contentItem: PC3.Label {
                    text: i18n("All Applications")
                    color: "black"
                }

                background: Rectangle {
                    color: "white"
                    border.color: Qt.rgba(0, 0, 0, 0.2)
                    border.width: 1
                    radius: 4
                }
            }
        }
    }

    function gofocus() {
        searchInput.forceActiveFocus();
        searchInput.selectAll();
    }

    function appendText(newText) {
        if (newText && newText.length > 0) {
            searchInput.text += newText;
            searchInput.cursorPosition = searchInput.text.length;
            gofocus();
        }
    }

    function backspace() {
        if (searchInput.text.length > 0) {
            searchInput.text = searchInput.text.slice(0, -1);
            searchInput.cursorPosition = searchInput.text.length;
            gofocus();
        }
    }

    function emptysearch() {
        searchInput.text = "";
        if (runnerModel) {
            runnerModel.query = "";
        }
        kicker.searching = false;
    }

    function clearSearch() {
        emptysearch();
    }

    Connections {
        target: typeof runnerModel !== "undefined" ? runnerModel : null

        function onCountChanged() {
            searchComponent.hasResults = runnerModel.count > 0;
        }
    }

    Component.onCompleted: {
        console.log("Search component with Windows logo button initialized");
    }
}
