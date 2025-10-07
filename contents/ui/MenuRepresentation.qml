import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.coreaddons 1.0 as KCoreAddons
import org.kde.plasma.private.quicklaunch 1.0
import org.kde.ksvg 1.0 as KSvg
import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtQml 2.15
import org.kde.kirigami 2.0 as Kirigami
import org.kde.plasma.plasmoid 2.0

FocusScope {
    id: rootItem

    property bool showGridFirst: Plasmoid.configuration.showGridFirst
    property bool searchvisible: Plasmoid.configuration.showSearch
    property bool showCategorizedApps: Plasmoid.configuration.showCategorizedApps !== undefined ? Plasmoid.configuration.showCategorizedApps : true
    property bool showAllAppsView: false

    property int visible_items: (Plasmoid.configuration.showInfoUser ? headingSvg.height : 0) +
    (rootItem.searchvisible == true ? 40 : 0) +
    (kicker.view_any_controls == true ? footer.height : 0) + Kirigami.Units.gridUnit
    property int cuadricula_hg: (kicker.cellSizeHeight * Plasmoid.configuration.numberRows)
    property int calc_width: (kicker.cellSizeWidth * Plasmoid.configuration.numberColumns) + Kirigami.Units.gridUnit
    property int calc_height: cuadricula_hg + (rootItem.visible_items)
    property int userShape: calculateUserShape(Plasmoid.configuration.userShape)
    property int space_width: resizeWidth() == 0 ? rootItem.calc_width : resizeWidth()
    property int space_height: resizeHeight() == 0 ? rootItem.calc_height : resizeHeight()
    property int dynamicColumns: Math.floor(rootItem.space_width / kicker.cellSizeWidth)
    property int dynamicRows: Math.ceil(kicker.count / dynamicColumns)

    Layout.maximumWidth: space_width
    Layout.minimumWidth: space_width
    Layout.minimumHeight: space_height
    Layout.maximumHeight: space_height
    focus: true

    KCoreAddons.KUser { id: kuser }
    Logic { id: logic }

    KSvg.FrameSvgItem {
        id: headingSvg
        width: parent.width + backgroundSvg.margins.left + backgroundSvg.margins.right
        height: Plasmoid.configuration.showInfoUser ? encabezado.height + Kirigami.Units.smallSpacing : Kirigami.Units.smallSpacing
        y: -backgroundSvg.margins.top
        x: -backgroundSvg.margins.left
        imagePath: "widgets/plasmoidheading"
        prefix: "header"
        opacity: Plasmoid.configuration.transparencyHead * 0.01
        visible: Plasmoid.configuration.showInfoUser
    }

    KSvg.FrameSvgItem {
        id: footerSvg
        visible: kicker.view_any_controls
        width: parent.width + backgroundSvg.margins.left + backgroundSvg.margins.right
        height: footer.Layout.preferredHeight + 2 + Kirigami.Units.smallSpacing * 3
        y: parent.height + Kirigami.Units.smallSpacing * 2
        x: backgroundSvg.margins.left
        imagePath: "widgets/plasmoidheading"
        prefix: "header"
        transform: Rotation { angle: 180; origin.x: width / 2; }
        opacity: Plasmoid.configuration.transparencyFooter * 0.01
    }

    ColumnLayout {
        id: container
        Layout.preferredHeight: rootItem.space_height

        Item {
            id: encabezado
            width: rootItem.space_width
            Layout.preferredHeight: 130
            visible: Plasmoid.configuration.showInfoUser

            Loader {
                id: head_
                sourceComponent: headComponent
                onLoaded: {
                    var pinButton = head_.item.pinButton;
                    if (!activeFocus && kicker.hideOnWindowDeactivate === false) {
                        if (!pinButton.checked) {
                            turnclose();
                        }
                    }
                }
            }
        }

        Item {
            id: gridComponent
            width: rootItem.space_width
            Layout.preferredHeight: (resizeHeight() == 0 ? rootItem.cuadricula_hg : resizeHeight() - rootItem.visible_items)

            SearchResultsGrid {
                id: searchGrid

                visible: kicker.searching && runnerModel.count > 0
                enabled: visible
                focus: visible

                anchors.fill: parent

                cellWidth: kicker.cellSizeWidth
                cellHeight: kicker.cellSizeWidth
                iconSize: kicker.iconSize
                showLabels: true

                model: runnerModel
                searching: kicker.searching
                searchQuery: searchLoader.item && searchLoader.item.searchField ? searchLoader.item.searchField.text : ""

                z: visible ? 100 : -1
                opacity: visible ? 1.0 : 0.0

                Behavior on opacity {
                    NumberAnimation { duration: 150; easing.type: Easing.OutCubic }
                }

                onKeyNavUp: {
                    if (searchLoader.item) {
                        searchLoader.item.gofocus();
                    }
                }

                onItemActivated: function(index, actionId, argument) {
                    console.log("SEARCH: Item activated, closing menu");
                    kicker.expanded = false;
                }

                onVisibleChanged: {
                    console.log("🔍 SEARCHGRID:", visible ? "SHOWING" : "HIDING", "| searching:", kicker.searching, "| count:", runnerModel.count);
                    if (visible) {
                        Qt.callLater(function() {
                            if (visible) {
                                selectFirst();
                            }
                        });
                    }
                }
            }

            ItemGridView {
                id: globalFavoritesGrid

                visible: kicker.showFavorites &&
                !kicker.searching &&
                !rootItem.showCategorizedApps &&
                !rootItem.showAllAppsView

                enabled: visible
                focus: visible

                anchors.fill: parent
                dragEnabled: true
                dropEnabled: true
                cellWidth: kicker.cellSizeWidth
                cellHeight: kicker.cellSizeHeight
                iconSize: kicker.iconSize
                model: globalFavorites
                z: visible ? 10 : -1

                onKeyNavUp: {
                    if (searchLoader.item) {
                        searchLoader.item.gofocus();
                    }
                }

                Keys.onPressed: function(event) {
                    kicker.keyIn = "favoritos : " + event.key;
                    if (event.modifiers & Qt.ControlModifier || event.modifiers & Qt.ShiftModifier) {
                        if (searchLoader.item) {
                            searchLoader.item.gofocus();
                        }
                        return;
                    } else if (event.key === Qt.Key_Tab) {
                        event.accepted = true;
                        if (searchLoader.item) {
                            searchLoader.item.gofocus();
                        }
                    } else if (event.key === Qt.Key_Escape) {
                        event.accepted = true;
                        rootItem.turnclose();
                    }
                }

                onVisibleChanged: {
                    console.log("⭐ FAVORITES:", visible ? "SHOWING" : "HIDING");
                    console.log("   Model count:", model ? model.count : "null");
                    console.log("   kicker.showFavorites:", kicker.showFavorites);
                    console.log("   showCategorizedApps:", rootItem.showCategorizedApps);
                    console.log("   showAllAppsView:", rootItem.showAllAppsView);

                    if (visible) {
                        Qt.callLater(function() {
                            if (globalFavoritesGrid.count > 0) {
                                globalFavoritesGrid.tryActivate(0, 0);
                                console.log("✅ Favorites activated");
                            } else {
                                console.warn("⚠️ No favorites to show! Right-click apps to add favorites.");
                            }
                        });
                    }
                }
            }

            AppsGridView {
                id: categoryGrid
                visible: rootItem.showCategorizedApps &&
                !kicker.searching &&
                !rootItem.showAllAppsView

                enabled: visible
                focus: visible

                anchors.fill: parent
                cellWidth: kicker.cellSizeWidth
                iconSize: kicker.iconSize
                model: rootModel
                z: visible ? 10 : -1

                onKeyNavUp: searchLoader.item.gofocus()

                Keys.onPressed: function(event) {
                    kicker.keyIn = "category grid : " + event.key;
                    if (event.modifiers & Qt.ControlModifier || event.modifiers & Qt.ShiftModifier) {
                        searchLoader.item.gofocus();
                        return;
                    } else if (event.key === Qt.Key_Tab) {
                        event.accepted = true;
                        searchLoader.item.gofocus();
                    } else if (event.key === Qt.Key_Escape) {
                        event.accepted = true;
                        if (categoryGrid.canGoBack()) {
                            categoryGrid.goBack();
                        } else {
                            rootItem.turnclose();
                        }
                    } else if (event.key === Qt.Key_Backspace) {
                        event.accepted = true;
                        if (!kicker.searching && categoryGrid.canGoBack()) {
                            categoryGrid.goBack();
                        } else {
                            searchLoader.item.gofocus();
                        }
                    } else if (event.text !== "") {
                        event.accepted = true;
                        searchLoader.item.appendText(event.text);
                    }
                }

                onVisibleChanged: {
                    console.log("📂 CATEGORY GRID:", visible ? "SHOWING" : "HIDING", "| searching:", kicker.searching);
                }
            }

            ItemGridView {
                id: allAppsCompleteGrid
                visible: rootItem.showAllAppsView && !kicker.searching
                enabled: visible
                focus: visible

                anchors.fill: parent
                cellWidth: kicker.cellSizeWidth
                cellHeight: kicker.cellSizeHeight
                iconSize: kicker.iconSize
                dropEnabled: false
                dragEnabled: false
                z: visible ? 10 : -1

                onKeyNavUp: searchLoader.item.gofocus()

                Keys.onPressed: function(event) {
                    kicker.keyIn = "all apps complete : " + event.key;
                    if (event.modifiers & Qt.ControlModifier || event.modifiers & Qt.ShiftModifier) {
                        searchLoader.item.gofocus();
                        return;
                    }
                    if (event.key === Qt.Key_Tab) {
                        event.accepted = true;
                        searchLoader.item.gofocus();
                    } else if (event.key === Qt.Key_Backspace) {
                        event.accepted = true;
                        if (kicker.searching) {
                            searchLoader.item.backspace();
                        }
                        searchLoader.item.gofocus();
                    } else if (event.key === Qt.Key_Escape) {
                        event.accepted = true;
                        if (kicker.searching) {
                            rootItem.reset();
                        } else {
                            rootItem.goBackToCategoryView();
                        }
                    } else if (event.text !== "") {
                        event.accepted = true;
                        searchLoader.item.appendText(event.text);
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    propagateComposedEvents: true
                    z: -1

                    onClicked: function(mouse) {
                        var cPos = mapToItem(allAppsCompleteGrid.contentItem, mouse.x, mouse.y);
                        var item = allAppsCompleteGrid.itemAt(cPos.x, cPos.y);

                        if (!item) {
                            rootItem.goBackToCategoryView();
                        } else {
                            mouse.accepted = false;
                        }
                    }
                }

                onVisibleChanged: {
                    console.log("📱 ALL APPS:", visible ? "SHOWING" : "HIDING");
                }
            }
        }

        Item {
            id: rowSearchField
            visible: rootItem.searchvisible
            Layout.preferredHeight: 40
            width: rootItem.space_width

            Loader {
                id: searchLoader
                anchors.fill: parent
                anchors.leftMargin: Kirigami.Units.largeSpacing
                anchors.rightMargin: Kirigami.Units.largeSpacing
                sourceComponent: searchComponent

                onLoaded: {
                    if (searchLoader.item) {
                        searchLoader.item.allAppsToggled.connect(function() {
                            if (rootItem.showAllAppsView) {
                                rootItem.goBackToCategoryView();
                            } else {
                                rootItem.showAllApps();
                            }
                        });

                        searchLoader.item.favoritesToggled.connect(function() {
                            console.log("🌟 FAVORITES BUTTON CLICKED");
                            console.log("Current state - showFavorites:", kicker.showFavorites,
                                        "showCategorizedApps:", rootItem.showCategorizedApps,
                                        "showAllAppsView:", rootItem.showAllAppsView);

                            var isFavoritesActive = kicker.showFavorites &&
                            !rootItem.showCategorizedApps &&
                            !rootItem.showAllAppsView;

                            if (isFavoritesActive) {
                                console.log("🔴 Turning OFF favorites");
                                kicker.showFavorites = false;
                                rootItem.showAllAppsView = false;
                                rootItem.showCategorizedApps = true;

                                Qt.callLater(function() {
                                    if (categoryGrid) {
                                        categoryGrid.resetToRoot();
                                        categoryGrid.focus = true;
                                        categoryGrid.tryActivate(0, 0);
                                    }
                                });
                            } else {
                                console.log("✅ Turning ON favorites");
                                console.log("Favorites model count:", globalFavorites ? globalFavorites.count : "null");

                                if (searchLoader.item) {
                                    searchLoader.item.emptysearch();
                                }
                                kicker.searching = false;

                                rootItem.showAllAppsView = false;
                                rootItem.showCategorizedApps = false;
                                kicker.showFavorites = true;

                                Qt.callLater(function() {
                                    if (globalFavoritesGrid) {
                                        globalFavoritesGrid.forceActiveFocus();
                                        if (globalFavoritesGrid.count > 0) {
                                            globalFavoritesGrid.tryActivate(0, 0);
                                            console.log("✅ Favorites grid focused with", globalFavoritesGrid.count, "items");
                                        } else {
                                            console.warn("⚠️ Favorites grid is EMPTY!");
                                            console.warn("Right-click on any app and select 'Add to Favorites'");
                                        }
                                    } else {
                                        console.error("❌ globalFavoritesGrid not found!");
                                    }
                                });
                            }
                        });
                    }
                }

                Connections {
                    target: rootItem
                    function onShowAllAppsViewChanged() {
                        if (searchLoader.item) {
                            searchLoader.item.allAppsActive = rootItem.showAllAppsView;
                        }
                    }
                }

                Connections {
                    target: kicker
                    function onShowFavoritesChanged() {
                        if (searchLoader.item) {
                            searchLoader.item.favoritesActive = kicker.showFavorites && !rootItem.showCategorizedApps;
                        }
                    }
                }
            }
        }

        Item {
            id: footer
            Layout.preferredHeight: 25
            visible: kicker.view_any_controls
            width: rootItem.space_width

            Loader {
                id: foot_
                sourceComponent: footerComponent
            }
        }
    }

    // DEBUG PANEL - NOW HIDDEN (SET TO false)
    Rectangle {
        visible: false  // ✅ CHANGED FROM true TO false - THIS FIXES THE BLACK DOT!
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        anchors.margins: 10
        width: 350
        height: 80
        color: Qt.rgba(0, 0, 0, 0.8)
        radius: 5
        z: 9999

        Column {
            x: 10
            y: (parent.height - height) / 2
            spacing: 2

            Text {
                text: "🔍 SEARCH DEBUG"
                color: "white"
                font.bold: true
                font.pointSize: 9
            }

            Text {
                text: "Query: '" + (searchLoader.item ? searchLoader.item.searchField.text : "none") + "'"
                color: "yellow"
                font.pointSize: 8
            }

            Text {
                text: "Searching: " + kicker.searching + " | RunnerModel Count: " + runnerModel.count
                color: "cyan"
                font.pointSize: 8
            }

            Text {
                text: "SearchGrid: visible=" + (searchGrid ? searchGrid.visible : false) +
                " | CategoryGrid: visible=" + (categoryGrid ? categoryGrid.visible : false)
                color: "lime"
                font.pointSize: 8
            }
        }
    }

    Keys.onPressed: function(event) {
        kicker.keyIn = "enhanced menurepresentation : " + event.key;
        event.accepted = true;

        if (event.modifiers & (Qt.ControlModifier | Qt.ShiftModifier)) {
            if (searchLoader.item) {
                searchLoader.item.gofocus();
            }
            return;
        }

        switch (event.key) {
            case Qt.Key_Escape:
                if (kicker.searching) {
                    reset();
                } else if (rootItem.showAllAppsView) {
                    rootItem.goBackToCategoryView();
                } else if (rootItem.showCategorizedApps && categoryGrid.canGoBack()) {
                    categoryGrid.goBack();
                } else {
                    turnclose();
                }
                break;

            case Qt.Key_Backspace:
                if (kicker.searching) {
                    if (searchLoader.item) {
                        searchLoader.item.backspace();
                        searchLoader.item.gofocus();
                    }
                } else if (rootItem.showAllAppsView) {
                    rootItem.goBackToCategoryView();
                } else if (rootItem.showCategorizedApps && categoryGrid.canGoBack()) {
                    categoryGrid.goBack();
                } else {
                    if (searchLoader.item) {
                        searchLoader.item.gofocus();
                    }
                }
                break;

            case Qt.Key_Tab:
            case Qt.Key_Backtab:
                if (searchLoader.item) {
                    searchLoader.item.gofocus();
                }
                break;

            default:
                if (isLetterOrNumber(event.text)) {
                    if (searchLoader.item) {
                        searchLoader.item.appendText(event.text);
                    }
                } else {
                    reset();
                }
                break;
        }

        if (!kicker.searching && searchLoader.item) {
            searchLoader.item.gofocus();
        }
    }

    Component { id: footerComponent; Footer {} }
    Component { id: searchComponent; Search {} }
    Component { id: headComponent; Head {} }

    function isLetterOrNumber(text) {
        return /^[a-zA-Z0-9]$/.test(text);
    }

    function turnclose() {
        if (searchLoader.item) {
            searchLoader.item.emptysearch();
        }

        kicker.searching = false;

        if (rootItem.showAllAppsView) {
            rootItem.showAllAppsView = false;
            rootItem.showCategorizedApps = true;
        }

        if (runnerModel) {
            runnerModel.query = "";
        }

        if (rootItem.showCategorizedApps) {
            categoryGrid.resetToRoot();
            categoryGrid.tryActivate(0, 0);
        } else if (kicker.showFavorites) {
            globalFavoritesGrid.tryActivate(0, 0);
        }

        kicker.expanded = false;
    }

    function reset() {
        if (searchLoader.item) {
            searchLoader.item.emptysearch();
        }

        kicker.searching = false;

        if (runnerModel) {
            runnerModel.query = "";
        }

        if (rootItem.showAllAppsView && allAppsCompleteGrid) {
            allAppsCompleteGrid.tryActivate(0, 0);
        } else if (kicker.showFavorites && globalFavoritesGrid) {
            globalFavoritesGrid.tryActivate(0, 0);
        } else if (rootItem.showCategorizedApps && categoryGrid) {
            categoryGrid.tryActivate(0, 0);
        }
    }

    function goBackToCategoryView() {
        rootItem.showAllAppsView = false;
        rootItem.showCategorizedApps = true;
        kicker.showFavorites = false;
        categoryGrid.resetToRoot();
        categoryGrid.focus = true;
        categoryGrid.tryActivate(0, 0);
    }

    function showAllApps() {
        rootItem.showAllAppsView = true;
        rootItem.showCategorizedApps = false;
        kicker.showFavorites = false;
        kicker.searching = false;

        if (searchLoader.item) {
            searchLoader.item.emptysearch();
        }

        var allAppsModel = null;

        if (kicker.allAppsModel && kicker.allAppsModel.count > 0) {
            allAppsModel = kicker.allAppsModel.modelForRow(0);
        }

        if (!allAppsModel && allAppsGrid.model) {
            allAppsModel = allAppsGrid.model;
        }

        if (!allAppsModel) {
            allAppsModel = rootModel;
        }

        if (allAppsModel) {
            allAppsCompleteGrid.model = allAppsModel;
        }

        allAppsCompleteGrid.focus = true;
        allAppsCompleteGrid.tryActivate(0, 0);
    }

    function resizeWidth() {
        var screenAvail = kicker.availableScreenRect;
        var screenGeom = kicker.screenGeometry;
        var screen = Qt.rect(screenAvail.x + screenGeom.x, screenAvail.y + screenGeom.y, screenAvail.width, screenAvail.height);
        if (screen.width > (kicker.cellSizeWidth * Plasmoid.configuration.numberColumns) + Kirigami.Units.gridUnit) {
            return 0;
        } else {
            return screen.width - Kirigami.Units.gridUnit * 2;
        }
    }

    function resizeHeight() {
        var screenAvail = kicker.availableScreenRect;
        var screenGeom = kicker.screenGeometry;
        var screen = Qt.rect(screenAvail.x + screenGeom.x, screenAvail.y + screenGeom.y, screenAvail.width, screenAvail.height);
        if (screen.height > (kicker.cellSizeHeight * Plasmoid.configuration.numberRows) + rootItem.visible_items + Kirigami.Units.gridUnit * 1.5) {
            return 0;
        } else {
            return screen.height - Kirigami.Units.gridUnit * 2;
        }
    }

    function calculateUserShape(shape) {
        switch (shape) {
            case 0: return (kicker.sizeImage * 0.85) / 2;
            case 1: return 8;
            case 2: return 0;
            default: return (kicker.sizeImage * 0.85) / 2;
        }
    }

    function setModels() {
        globalFavoritesGrid.model = globalFavorites;

        if (rootModel && rootModel.count > 0) {
            // No need to set allAppsGrid.model here
        }

        if (kicker.allAppsModel && kicker.allAppsModel.count > 0) {
            var flatModel = kicker.allAppsModel.modelForRow(0);
            if (flatModel) {
                allAppsCompleteGrid.model = flatModel;
            }
        }
    }

    onActiveFocusChanged: {
        if (!activeFocus && kicker.hideOnWindowDeactivate === false) {
            if (head_.item && head_.item.pinButton) {
                if (!head_.item.pinButton.checked) {
                    turnclose();
                }
            }
        }
    }

    Component.onCompleted: {
        rootModel.refreshed.connect(setModels);
        rootModel.refresh();

        if (rootItem.showCategorizedApps) {
            categoryGrid.tryActivate(0, 0);
        } else if (kicker.showFavorites) {
            globalFavoritesGrid.tryActivate(0, 0);
        }

        console.log("MenuRepresentation initialized with FIXED search functionality");

        Qt.callLater(function() {
            console.log("=== FAVORITES DEBUG ===");
            console.log("globalFavorites exists:", globalFavorites ? "YES" : "NO");
            console.log("globalFavorites count:", globalFavorites ? globalFavorites.count : "null");
            console.log("Favorite apps config:", Plasmoid.configuration.favoriteApps);

            if (globalFavorites && globalFavorites.count === 0) {
                console.warn("⚠️ NO FAVORITES FOUND! Add some apps to favorites first.");
            }
        });
    }
}
