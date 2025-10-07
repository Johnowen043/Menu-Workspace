/*   Copyright (C) 2024-2024 by Randy Abiel Cabrera                        */

import QtQuick 2.15
import QtQuick.Layouts 1.15

import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.core as PlasmaCore
import org.kde.ksvg 1.0 as KSvg
import org.kde.plasma.plasmoid 2.0
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.plasma.private.kicker 0.1 as Kicker

PlasmoidItem {
    id: kicker
    anchors.fill: parent
    signal reset

    property var searchRunners: Plasmoid.configuration.searchRunners || [
        "krunner_services",
        "krunner_systemsettings",
        "baloosearch",
        "calculator",
        "unitconverter",
        "krunner_recentdocuments",
        "locations"
    ]

    property bool isDash: Plasmoid.pluginName === "org.kde.plasma.kickerdash"
    switchWidth: isDash || !fullRepresentationItem ? 0 : fullRepresentationItem.Layout.minimumWidth
        switchHeight: isDash || !fullRepresentationItem ? 0 : fullRepresentationItem.Layout.minimumHeight
            compactRepresentation: isDash ? null : compactRepresentation
            preferredRepresentation: isDash ? fullRepresentation : null
            fullRepresentation: isDash ? compactRepresentation : menuRepresentation

            // Configuration properties
            property bool showFavorites: Plasmoid.configuration.showFavoritesFirst
            property Item dragSource: null
            property bool searching: false

            // PLASMA-DRAWER STYLE: Category hiding configuration
            property bool hideAllAppsCategory: Plasmoid.configuration.hideAllAppsCategory !== undefined ? Plasmoid.configuration.hideAllAppsCategory : true
            property bool hidePowerCategory: Plasmoid.configuration.hidePowerCategory !== undefined ? Plasmoid.configuration.hidePowerCategory : true
            property bool hideSessionsCategory: Plasmoid.configuration.hideSessionsCategory !== undefined ? Plasmoid.configuration.hideSessionsCategory : true

            // Keyboard properties
            property int currentColumn: 0
            property int currentRow: 0
            property int currentIndex: 0
            property int count: 0
            property string keyIn: ""

            // Commands
            readonly property string aboutThisComputerCMD: Plasmoid.configuration.aboutThisComputerSettings
            readonly property string systemPreferencesCMD: Plasmoid.configuration.systemPreferencesSettings
            readonly property string homeCMD: Plasmoid.configuration.homeSettings
            readonly property string appStoreCMD: Plasmoid.configuration.appStoreSettings
            readonly property string forceQuitCMD: Plasmoid.configuration.forceQuitSettings
            property bool view_any_controls: Plasmoid.configuration.rebootEnabled || Plasmoid.configuration.shutDownEnabled || Plasmoid.configuration.aboutThisComputerEnabled || Plasmoid.configuration.systemPreferencesEnabled || Plasmoid.configuration.appStoreEnabled || Plasmoid.configuration.forceQuitEnabled || Plasmoid.configuration.sleepEnabled || Plasmoid.configuration.lockScreenEnabled || Plasmoid.configuration.logOutEnabled || Plasmoid.configuration.homeEnabled

            // Image and icon properties
            property int sizeImage: Kirigami.Units.iconSizes.large * 2.5
            property int cellSizeHeight: iconSize + Kirigami.Units.gridUnit * 2 + (2 * Math.max(highlightItemSvg.margins.top + highlightItemSvg.margins.bottom, highlightItemSvg.margins.left + highlightItemSvg.margins.right))
            property int cellSizeWidth: cellSizeHeight + Kirigami.Units.gridUnit

            property int iconSize: {
                switch (Plasmoid.configuration.appsIconSize) {
                    case 0: return Kirigami.Units.iconSizes.smallMedium;
                    case 1: return Kirigami.Units.iconSizes.medium;
                    case 2: return Kirigami.Units.iconSizes.large;
                    case 3: return Kirigami.Units.iconSizes.huge;
                    default: return 64
                }
            }

            Plasmoid.icon: Plasmoid.configuration.useCustomButtonImage ? Plasmoid.configuration.customButtonImage : Plasmoid.configuration.icon

            // Models - DECLARE BEFORE USE
            property QtObject globalFavorites: rootModel.favoritesModel
            property QtObject systemFavorites: hidePowerCategory ? null : rootModel.systemFavoritesModel
            property QtObject allAppsModel: null
            property bool showCategories: false

            // MAIN ROOT MODEL
            Kicker.RootModel {
                id: rootModel
                autoPopulate: false
                appNameFormat: 0
                flat: true
                sorted: true
                showSeparators: false
                appletInterface: kicker

                showAllApps: !kicker.hideAllAppsCategory
                showRecentApps: false
                showRecentDocs: false
                showPowerSession: !kicker.hidePowerCategory

                onShowRecentAppsChanged: {
                    Plasmoid.configuration.showRecentApps = showRecentApps;
                }
                onShowRecentDocsChanged: {
                    Plasmoid.configuration.showRecentDocs = showRecentDocs;
                }
                onRecentOrderingChanged: {
                    Plasmoid.configuration.recentOrdering = recentOrdering;
                }
            }

            // DEDICATED FLAT MODEL FOR ALL APPS
            Kicker.RootModel {
                id: flatAppsModel
                autoPopulate: false
                appNameFormat: 0
                flat: true
                sorted: true
                showSeparators: false
                appletInterface: kicker

                showAllApps: true
                showRecentApps: false
                showRecentDocs: false
                showPowerSession: false

                Component.onCompleted: {
                    kicker.allAppsModel = this;
                    refresh();
                }
            }

            // RUNNER MODEL
            Kicker.RunnerModel {
                id: runnerModel
                appletInterface: kicker
                favoritesModel: kicker.globalFavorites

                runners: [
                    "krunner_services",
                    "baloosearch",
                    "calculator",
                    "krunner_systemsettings"
                ]

                onQueryChanged: {
                    if (query && query.length > 0) {
                        console.log("Processing query:", query, "with runners:", runners);
                    }
                }

                onCountChanged: {
                    console.log("PLASMA-DRAWER RUNNERMODEL: Count changed to:", count);

                    if (count > 0) {
                        console.log("=== PLASMA-DRAWER RESULTS DEBUG ===");

                        for (var i = 0; i < Math.min(count, 5); i++) {
                            try {
                                var modelIndex = index(i, 0);
                                var itemName = data(modelIndex, Qt.DisplayRole) || "";
                                var itemUrl = data(modelIndex, Qt.UserRole) || "";
                                var itemIcon = data(modelIndex, Qt.DecorationRole) || "";
                                var itemSubtext = data(modelIndex, Qt.UserRole + 1) || "";

                                console.log("Result " + i + ":", itemName);
                                console.log("  URL:", itemUrl);
                                console.log("  Icon:", itemIcon);
                                console.log("  Subtext:", itemSubtext);
                            } catch (error) {
                                console.error("Error reading result " + i + ":", error);
                            }
                        }
                        console.log("=== END PLASMA-DRAWER RESULTS ===");
                    }
                }

                function triggerIndex(idx) {
                    console.log("PLASMA-DRAWER RUNNERMODEL: triggerIndex called with:", idx, "of", count);

                    if (idx < 0 || idx >= count) {
                        console.warn("PLASMA-DRAWER RUNNERMODEL: Invalid index:", idx);
                        return false;
                    }

                    try {
                        console.log("PLASMA-DRAWER RUNNERMODEL: Attempting direct trigger");
                        var result = trigger(idx, "", null);
                        if (result !== false && result !== undefined) {
                            console.log("PLASMA-DRAWER RUNNERMODEL: Direct trigger SUCCESS");
                            return true;
                        }

                        console.log("PLASMA-DRAWER RUNNERMODEL: Attempting manual execution");
                        var modelIndex = index(idx, 0);
                        var itemUrl = data(modelIndex, Qt.UserRole);
                        var itemName = data(modelIndex, Qt.DisplayRole);
                        var itemType = data(modelIndex, Qt.UserRole + 1);

                        console.log("PLASMA-DRAWER RUNNERMODEL: Manual details - Name:", itemName, "URL:", itemUrl, "Type:", itemType);

                        if (itemUrl && processRunner) {
                            var urlString = itemUrl.toString();
                            console.log("PLASMA-DRAWER RUNNERMODEL: Executing command:", urlString);
                            processRunner.runCommand(urlString);
                            console.log("PLASMA-DRAWER RUNNERMODEL: Manual execution SUCCESS");
                            return true;
                        }

                    } catch (error) {
                        console.error("PLASMA-DRAWER RUNNERMODEL: Trigger error:", error);
                    }

                    console.warn("PLASMA-DRAWER RUNNERMODEL: All trigger methods FAILED for index:", idx);
                    return false;
                }

                Component.onCompleted: {
                    console.log("PLASMA-DRAWER RUNNERMODEL: Initialized with runners:", runners);
                }
            }

            // Test Timer
            Timer {
                id: runnerTestTimer
                interval: 2000
                running: true
                repeat: false
                onTriggered: {
                    console.log("=== AUTO RUNNERMODEL TEST (2s after init) ===");
                    if (typeof runnerModel !== "undefined" && runnerModel) {
                        console.log("✓ runnerModel is accessible");
                        console.log("  Count:", runnerModel.count);
                        console.log("  Query:", runnerModel.query);
                        console.log("  Runners:", runnerModel.runners);

                        console.log("Testing with query 'test'");
                        runnerModel.query = "test";

                        Qt.callLater(function() {
                            console.log("  Result count:", runnerModel.count);
                        });
                    } else {
                        console.error("✗ runnerModel is NOT accessible!");
                    }
                }
            }

            // Helper Components
            Kicker.DragHelper {
                id: dragHelper
                dragIconSize: Kirigami.Units.iconSizes.medium
            }

            Kicker.ProcessRunner {
                id: processRunner
            }

            Kicker.WindowSystem {
                id: windowSystem
            }

            // Model Connections
            Connections {
                target: kicker.globalFavorites
                function onFavoritesChanged() {
                    Plasmoid.configuration.favoriteApps = target.favorites;
                }
            }

            Connections {
                target: kicker.hidePowerCategory ? null : kicker.systemFavorites
                function onFavoritesChanged() {
                    if (target && !kicker.hidePowerCategory) {
                        Plasmoid.configuration.favoriteSystemActions = target.favorites;
                    }
                }
            }

            // Configuration Connections
            Connections {
                target: Plasmoid.configuration

                function onFavoriteAppsChanged() {
                    console.log("⭐ CONFIG CHANGED: Favorites =", Plasmoid.configuration.favoriteApps);
                    if (kicker.globalFavorites) {
                        kicker.globalFavorites.favorites = Plasmoid.configuration.favoriteApps;
                        console.log("⭐ Applied to model, new count:", kicker.globalFavorites.count);
                    }
                }

                function onFavoriteSystemActionsChanged() {
                    if (kicker.systemFavorites && !kicker.hidePowerCategory) {
                        kicker.systemFavorites.favorites = Plasmoid.configuration.favoriteSystemActions;
                    }
                }

                function onHiddenApplicationsChanged() {
                    rootModel.refresh();
                }

                function onHideAllAppsCategoryChanged() {
                    kicker.hideAllAppsCategory = Plasmoid.configuration.hideAllAppsCategory;
                    rootModel.showAllApps = !kicker.hideAllAppsCategory;
                    rootModel.refresh();
                }

                function onHidePowerCategoryChanged() {
                    kicker.hidePowerCategory = Plasmoid.configuration.hidePowerCategory;
                    rootModel.showPowerSession = !kicker.hidePowerCategory;

                    if (kicker.hidePowerCategory && rootModel.systemFavoritesModel) {
                        rootModel.systemFavoritesModel.favorites = [];
                    }
                    rootModel.refresh();
                }

                function onHideSessionsCategoryChanged() {
                    kicker.hideSessionsCategory = Plasmoid.configuration.hideSessionsCategory;
                    if (runnerModel.updateRunnersForQuery) {
                        runnerModel.updateRunnersForQuery(runnerModel.query || "");
                    }
                }
            }

            // Kicker Connections
            Connections {
                target: kicker
                function onExpandedChanged(expanded) {
                    if (expanded) {
                        windowSystem.monitorWindowVisibility(Plasmoid.fullRepresentationItem);
                        justOpenedTimer.start();
                    } else {
                        kicker.reset();
                    }
                }
            }

            // UI Components
            PlasmaExtras.Menu {
                id: contextMenu
                PlasmaExtras.MenuItem {
                    action: Plasmoid.internalAction("configure")
                }
            }

            PlasmaExtras.Highlight {
                id: delegateHighlight
                visible: false
                z: -1
            }

            Kirigami.Heading {
                id: dummyHeading
                visible: false
                width: 0
                level: 5
            }

            // SVG Components
            KSvg.FrameSvgItem {
                id: panelSvg
                visible: false
                imagePath: "widgets/panel-background"
            }

            KSvg.FrameSvgItem {
                id: scrollbarSvg
                visible: false
                imagePath: "widgets/scrollbar"
            }

            KSvg.FrameSvgItem {
                id: highlightItemSvg
                visible: false
                imagePath: "widgets/viewitem"
                prefix: "hover"
            }

            KSvg.FrameSvgItem {
                id: listItemSvg
                visible: false
                imagePath: "widgets/listitem"
                prefix: "normal"
            }

            KSvg.FrameSvgItem {
                id: backgroundSvg
                visible: false
                imagePath: "dialogs/background"
            }

            PC3.Label {
                id: toolTipDelegate
                width: contentWidth
                height: undefined
                property Item toolTip
                text: toolTip ? toolTip.text : ""
                textFormat: Text.PlainText
            }

            // Plasmoid Actions
            Plasmoid.contextualActions: [
                PlasmaCore.Action {
                    text: i18n("Edit Applications…")
                    icon.name: "kmenuedit"
                    visible: Plasmoid.immutability !== PlasmaCore.Types.SystemImmutable
                    onTriggered: processRunner.runMenuEditor()
                }
            ]

            // Timers
            Timer {
                id: justOpenedTimer
                repeat: false
                interval: 600
            }

            // Components
            Component {
                id: compactRepresentation
                CompactRepresentation {}
            }

            Component {
                id: menuRepresentation
                MenuRepresentation {}
            }

            // Main Initialization
            Component.onCompleted: {
                if (Plasmoid.hasOwnProperty("activationTogglesExpanded")) {
                    Plasmoid.activationTogglesExpanded = !kicker.isDash
                }

                windowSystem.focusIn.connect(enableHideOnWindowDeactivate);
                kicker.hideOnWindowDeactivate = true;
                updateSvgMetrics();
                PlasmaCore.Theme.themeChanged.connect(updateSvgMetrics);
                rootModel.refreshed.connect(reset);
                dragHelper.dropped.connect(resetDragSource);

                if (Plasmoid.configuration.showCategorizedApps === undefined) {
                    Plasmoid.configuration.showCategorizedApps = true;
                }

                console.log("Kicker main.qml initialized with FIXED RunnerModel for proper application search");

                // FORCE INITIALIZE FAVORITES - PROPER WAY
                Qt.callLater(function() {
                    if (kicker.globalFavorites) {
                        console.log("⭐ Initializing favorites model...");

                        // Initialize the model first
                        kicker.globalFavorites.initForClient("org.kde.plasma.kicker.favorites.instance-" + Plasmoid.id);

                        // Load favorites from config
                        if (Plasmoid.configuration.favoriteApps && Plasmoid.configuration.favoriteApps.length > 0) {
                            console.log("⭐ Setting favorites:", Plasmoid.configuration.favoriteApps);
                            kicker.globalFavorites.favorites = Plasmoid.configuration.favoriteApps;

                            // Check result after a delay
                            Qt.callLater(function() {
                                console.log("⭐ Favorites count:", kicker.globalFavorites.count);
                                console.log("⭐ Favorites list:", kicker.globalFavorites.favorites);

                                if (kicker.globalFavorites.count === 0) {
                                    console.error("❌ FAVORITES FAILED TO LOAD!");
                                    console.error("   This might be a KActivitiesStats issue");
                                    console.error("   Try: sudo systemctl --user restart plasma-kactivitymanagerd");
                                }
                            });
                        } else {
                            console.warn("⚠️ No favorite apps in configuration");
                        }
                    } else {
                        console.error("❌ globalFavorites model not found!");
                    }
                });
            }
            // Functions
            function updateSvgMetrics() {
                // SVG metrics update logic
            }

            function resetDragSource() {
                dragSource = null;
            }

            function toggle() {
                kicker.expanded = !kicker.expanded;
            }

            function action_menuedit() {
                processRunner.runMenuEditor();
            }

            function enableHideOnWindowDeactivate() {
                kicker.hideOnWindowDeactivate = true;
            }
}
