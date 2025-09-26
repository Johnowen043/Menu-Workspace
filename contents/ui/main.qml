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

PlasmoidItem
{
    id: kicker
    anchors.fill: parent
    signal reset

    property bool isDash: Plasmoid.pluginName === "org.kde.plasma.kickerdash"
    switchWidth: isDash || !fullRepresentationItem ? 0 :fullRepresentationItem.Layout.minimumWidth
        switchHeight: isDash || !fullRepresentationItem ? 0 :fullRepresentationItem.Layout.minimumHeight
            compactRepresentation: isDash ? null : compactRepresentation
            preferredRepresentation: isDash ?fullRepresentation : null
            fullRepresentation: isDash ? compactRepresentation : menuRepresentation

            // Configuration properties
            property bool showFavorites : Plasmoid.configuration.showFavoritesFirst
            property Item dragSource: null
            property bool searching: false

            // PLASMA-DRAWER STYLE: Category hiding configuration
            property bool hideAllAppsCategory: Plasmoid.configuration.hideAllAppsCategory !== undefined ? Plasmoid.configuration.hideAllAppsCategory : true
            property bool hidePowerCategory: Plasmoid.configuration.hidePowerCategory !== undefined ? Plasmoid.configuration.hidePowerCategory : true
            property bool hideSessionsCategory: Plasmoid.configuration.hideSessionsCategory !== undefined ? Plasmoid.configuration.hideSessionsCategory : true

            // Keyboard properties
            property int currentColumn : 0
            property int currentRow : 0
            property int currentIndex: 0
            property int count: 0
            property string keyIn  : ""

            // Commands
            readonly property string aboutThisComputerCMD: Plasmoid.configuration.aboutThisComputerSettings
            readonly property string systemPreferencesCMD: Plasmoid.configuration.systemPreferencesSettings
            readonly property string homeCMD: Plasmoid.configuration.homeSettings
            readonly property string appStoreCMD: Plasmoid.configuration.appStoreSettings
            readonly property string forceQuitCMD: Plasmoid.configuration.forceQuitSettings
            property bool view_any_controls : Plasmoid.configuration.rebootEnabled || Plasmoid.configuration.shutDownEnabled || Plasmoid.configuration.aboutThisComputerEnabled || Plasmoid.configuration.systemPreferencesEnabled || Plasmoid.configuration.appStoreEnabled || Plasmoid.configuration.forceQuitEnabled ||  Plasmoid.configuration.sleepEnabled || Plasmoid.configuration.lockScreenEnabled  || Plasmoid.configuration.logOutEnabled ||  Plasmoid.configuration.homeEnabled

            // Image and icon properties
            property int sizeImage: Kirigami.Units.iconSizes.large * 2.5
            property int cellSizeHeight: iconSize + Kirigami.Units.gridUnit * 2 + (2 * Math.max(highlightItemSvg.margins.top +  highlightItemSvg.margins.bottom, highlightItemSvg.margins.left + highlightItemSvg.margins.right))
            property int cellSizeWidth: cellSizeHeight + Kirigami.Units.gridUnit

            property int iconSize:{switch(Plasmoid.configuration.appsIconSize){
                case 0: return Kirigami.Units.iconSizes.smallMedium;
                case 1: return Kirigami.Units.iconSizes.medium;
                case 2: return Kirigami.Units.iconSizes.large;
                case 3: return Kirigami.Units.iconSizes.huge;
                default: return 64}}

                Plasmoid.icon: Plasmoid.configuration.useCustomButtonImage ? Plasmoid.configuration.customButtonImage : Plasmoid.configuration.icon

                // Models
                property QtObject globalFavorites: rootModel.favoritesModel

                // PLASMA-DRAWER STYLE: Conditionally controlled systemFavorites
                property QtObject systemFavorites: hidePowerCategory ? null : rootModel.systemFavoritesModel

                // Create a dedicated flat model for "All Apps" functionality
                property QtObject allAppsModel: null

                Kicker.RootModel
                {
                    id: rootModel
                    autoPopulate: false
                    appNameFormat: 0
                    flat: true
                    sorted: true
                    showSeparators: false
                    appletInterface: kicker

                    // PLASMA-DRAWER STYLE: Control whether "All Applications" category appears
                    showAllApps: !hideAllAppsCategory

                    showRecentApps: false
                    showRecentDocs: false

                    // PLASMA-DRAWER STYLE: Control power session display
                    showPowerSession: !hidePowerCategory

                    onShowRecentAppsChanged:{ Plasmoid.configuration.showRecentApps = showRecentApps;}
                    onShowRecentDocsChanged: { Plasmoid.configuration.showRecentDocs = showRecentDocs;}
                    onRecentOrderingChanged: {Plasmoid.configuration.recentOrdering = recentOrdering;}

                    Component.onCompleted:
                    {
                        favoritesModel.initForClient("org.kde.plasma.kicker.favorites.instance-" + Plasmoid.id)
                        if (!Plasmoid.configuration.favoritesPortedToKAstats)
                        {
                            if (favoritesModel.count < 1)
                            {
                                favoritesModel.portOldFavorites(Plasmoid.configuration.favoriteApps);
                            }
                            Plasmoid.configuration.favoritesPortedToKAstats = true;
                        }

                        // PLASMA-DRAWER STYLE: Force systemFavoritesModel to be empty if hiding power
                        if (hidePowerCategory && systemFavoritesModel) {
                            systemFavoritesModel.favorites = [];  // Empty the model to trigger count == 0
                        }
                    }
                }

                // DEDICATED FLAT MODEL FOR ALL APPS - This ensures we get ALL applications
                Kicker.RootModel
                {
                    id: flatAppsModel
                    autoPopulate: false
                    appNameFormat: 0
                    flat: true
                    sorted: true
                    showSeparators: false
                    appletInterface: kicker

                    // CRITICAL: Force showing all apps without categories
                    showAllApps: true
                    showRecentApps: false
                    showRecentDocs: false
                    showPowerSession: false

                    Component.onCompleted: {
                        // Set this as the dedicated all apps model
                        kicker.allAppsModel = this;
                        refresh();
                    }
                }

                // ENHANCED RUNNER MODEL with comprehensive search capabilities
                Kicker.RunnerModel
                {
                    id: runnerModel
                    appletInterface: kicker
                    favoritesModel: globalFavorites

                    // Enhanced runners list for comprehensive search
                    runners: getEnhancedRunners()
                }

                // Enhanced runner configuration function
                function getEnhancedRunners() {
                    var runners = [
                        "krunner_services",           // Applications - CRITICAL for finding apps
                        "krunner_systemsettings",     // System Settings
                        "calculator",                 // Calculator
                        "unitconverter",             // Unit Converter
                        "baloosearch",               // File Search
                        "krunner_recentdocuments",   // Recent Files
                        "krunner_placesrunner",      // Places
                        "krunner_bookmarksrunner",   // Bookmarks
                        "krunner_webshortcuts",      // Web Search
                        "krunner_shell",             // Command Line
                        "locations",                 // Locations
                        "windows",                   // Windows
                        "krunner_dictionary",        // Dictionary
                        "krunner_kill",              // Terminate Applications
                        "krunner_kwin",              // KWin
                        "krunner_appstream"          // Software Center
                    ];

                    // Conditionally add runners based on category hiding preferences
                    if (!hideSessionsCategory) {
                        runners.push("krunner_sessions");
                    }

                    if (!hidePowerCategory) {
                        runners.push("krunner_powerdevil");
                    }

                    // Add extra runners if configured
                    if (Plasmoid.configuration.useExtraRunners && Plasmoid.configuration.extraRunners) {
                        var extraRunners = Plasmoid.configuration.extraRunners;
                        for (var i = 0; i < extraRunners.length; i++) {
                            if (runners.indexOf(extraRunners[i]) === -1) {
                                runners.push(extraRunners[i]);
                            }
                        }
                    }

                    console.log("Enhanced runners configured:", runners);
                    return runners;
                }

                Kicker.DragHelper{id: dragHelper
                    dragIconSize: Kirigami.Units.iconSizes.medium}
                    Kicker.ProcessRunner {id: processRunner}
                    Kicker.WindowSystem { id: windowSystem}

                    Connections
                    {
                        target: globalFavorites
                        function onFavoritesChanged() { Plasmoid.configuration.favoriteApps = target.favorites;}
                    }

                    // PLASMA-DRAWER STYLE: Conditional systemFavorites connection
                    Connections
                    {
                        target: hidePowerCategory ? null : systemFavorites
                        function onFavoritesChanged() {
                            if (target && !hidePowerCategory) {
                                Plasmoid.configuration.favoriteSystemActions = target.favorites;
                            }
                        }
                    }

                    Connections
                    {
                        target: Plasmoid.configuration
                        function onFavoriteAppsChanged () { globalFavorites.favorites = Plasmoid.configuration.favoriteApps;}
                        function onFavoriteSystemActionsChanged () {
                            if (systemFavorites && !hidePowerCategory) {
                                systemFavorites.favorites = Plasmoid.configuration.favoriteSystemActions;
                            }
                        }
                        function onHiddenApplicationsChanged(){ rootModel.refresh();}

                        // PLASMA-DRAWER STYLE: React to category hiding changes
                        function onHideAllAppsCategoryChanged() {
                            hideAllAppsCategory = Plasmoid.configuration.hideAllAppsCategory;
                            rootModel.showAllApps = !hideAllAppsCategory;
                            runnerModel.runners = getEnhancedRunners();
                            rootModel.refresh();
                        }
                        function onHidePowerCategoryChanged() {
                            hidePowerCategory = Plasmoid.configuration.hidePowerCategory;
                            rootModel.showPowerSession = !hidePowerCategory;
                            runnerModel.runners = getEnhancedRunners();

                            // Force systemFavoritesModel to be empty
                            if (hidePowerCategory && rootModel.systemFavoritesModel) {
                                rootModel.systemFavoritesModel.favorites = [];
                            }
                            rootModel.refresh();
                        }
                        function onHideSessionsCategoryChanged() {
                            hideSessionsCategory = Plasmoid.configuration.hideSessionsCategory;
                            runnerModel.runners = getEnhancedRunners();
                        }
                        function onUseExtraRunnersChanged() {
                            runnerModel.runners = getEnhancedRunners();
                        }
                        function onExtraRunnersChanged() {
                            runnerModel.runners = getEnhancedRunners();
                        }
                    }

                    Connections
                    {
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

                    // UI Components (unchanged)
                    PlasmaExtras.Menu
                    {   id: contextMenu
                        PlasmaExtras.MenuItem {action: Plasmoid.internalAction("configure")}
                    }
                    PlasmaExtras.Highlight
                    {
                        id: delegateHighlight
                        visible: false
                        z: -1
                    }
                    Kirigami.Heading
                    {
                        id: dummyHeading
                        visible: false
                        width: 0
                        level: 5
                    }

                    // SVG Components (unchanged)
                    KSvg.FrameSvgItem
                    {
                        id : panelSvg
                        visible: false
                        imagePath: "widgets/panel-background"
                    }
                    KSvg.FrameSvgItem
                    {
                        id : scrollbarSvg
                        visible: false
                        imagePath: "widgets/scrollbar"
                    }
                    KSvg.FrameSvgItem
                    {
                        id: highlightItemSvg
                        visible: false
                        imagePath: "widgets/viewitem"
                        prefix: "hover"
                    }
                    KSvg.FrameSvgItem
                    {
                        id: listItemSvg
                        visible: false
                        imagePath: "widgets/listitem"
                        prefix: "normal"
                    }
                    KSvg.FrameSvgItem
                    {
                        id : backgroundSvg
                        visible: false
                        imagePath: "dialogs/background"
                    }

                    PC3 .Label
                    {
                        id: toolTipDelegate
                        width: contentWidth
                        height: undefined
                        property Item toolTip
                        text: toolTip ? toolTip.text : ""
                        textFormat: Text.PlainText
                    }

                    Plasmoid.contextualActions: [
                        PlasmaCore.Action {
                            text: i18n("Edit Applications…")
                            icon.name: "kmenuedit"
                            visible: Plasmoid.immutability !== PlasmaCore.Types.SystemImmutable
                            onTriggered: processRunner.runMenuEditor()
                        }
                    ]

                    // Components
                    Timer {
                        id: justOpenedTimer
                        repeat: false
                        interval: 600
                    }
                    Component {
                        id: compactRepresentation
                        CompactRepresentation {}
                    }
                    Component {
                        id: menuRepresentation
                        MenuRepresentation {}
                    }

                    Component.onCompleted:{
                        if (Plasmoid.hasOwnProperty("activationTogglesExpanded")) {
                            Plasmoid.activationTogglesExpanded = !kicker.isDash
                        }
                        windowSystem.focusIn.connect(enableHideOnWindowDeactivate);
                        kicker.hideOnWindowDeactivate = true;
                        kicker.FramelessWindowHint=true;
                        updateSvgMetrics();
                        PlasmaCore.Theme.themeChanged.connect(updateSvgMetrics);
                        rootModel.refreshed.connect(reset);
                        dragHelper.dropped.connect(resetDragSource);

                        // SET CATEGORY VIEW AS DEFAULT
                        if (Plasmoid.configuration.showCategorizedApps === undefined) {
                            Plasmoid.configuration.showCategorizedApps = true;
                        }
                    }

                    // Functions (unchanged)
                    onSystemFavoritesChanged:{}
                    function updateSvgMetrics() {}
                    function resetDragSource() { dragSource = null;}
                    function toggle() { kicker.expanded=!kicker.expanded}
                    function action_menuedit() { processRunner.runMenuEditor();}
                    function enableHideOnWindowDeactivate() { kicker.hideOnWindowDeactivate = true;}
}
