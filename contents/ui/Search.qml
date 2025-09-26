import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.coreaddons 1.0 as KCoreAddons
import org.kde.kquickcontrolsaddons 2.0
import org.kde.plasma.private.quicklaunch 1.0
import QtQuick.Controls 2.15
import org.kde.ksvg 1.0 as KSvg
import org.kde.plasma.plasma5support 2.0 as P5Support
import Qt5Compat.GraphicalEffects
import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtQml 2.15
import org.kde.kirigami 2.0  as Kirigami
import org.kde.plasma.plasmoid 2.0
import org.kde.kcmutils as KCM
import org.kde.plasma.private.sessions as Sessions

Item
{
    // Enhanced search runners configuration based on plasma-drawer approach
    property var searchRunners: getFilteredSearchRunners()

    // Configuration for hiding categories (like plasma-drawer)
    property bool hideAllAppsCategory: Plasmoid.configuration.hideAllAppsCategory || true
    property bool hidePowerCategory: Plasmoid.configuration.hidePowerCategory || true
    property bool hideSessionsCategory: Plasmoid.configuration.hideSessionsCategory || true

    // Complete list of available runners for search functionality
    readonly property var availableRunners: [
        "krunner_services",           // Applications
        "krunner_systemsettings",     // System Settings
        "krunner_sessions",           // Desktop Sessions
        "krunner_powerdevil",         // Power Management
        "calculator",                 // Calculator
        "unitconverter",             // Unit Converter
        "krunner_bookmarksrunner",   // Bookmarks
        "krunner_recentdocuments",   // Recent Files
        "krunner_placesrunner",      // Places
        "baloosearch",               // File Search
        "krunner_shell",             // Command Line
        "krunner_webshortcuts",      // Web Search
        "locations",                 // Locations
        "krunner_dictionary",        // Dictionary
        "krunner_kill",              // Terminate Applications
        "krunner_kwin",              // KWin
        "windows",                   // Windows
        "krunner_appstream"          // Software Center
    ]

    // Enhanced search runners filtering function
    function getFilteredSearchRunners() {
        var runners = [];

        // Always include essential runners for search functionality
        runners.push("krunner_services");  // Essential for finding applications
        runners.push("krunner_systemsettings");
        runners.push("calculator");
        runners.push("unitconverter");

        // Add file and document search
        runners.push("baloosearch");
        runners.push("krunner_recentdocuments");
        runners.push("krunner_placesrunner");

        // Add web and bookmark search
        runners.push("krunner_bookmarksrunner");
        runners.push("krunner_webshortcuts");

        // Add utility runners
        runners.push("krunner_shell");
        runners.push("locations");
        runners.push("windows");
        runners.push("krunner_dictionary");
        runners.push("krunner_kill");
        runners.push("krunner_kwin");
        runners.push("krunner_appstream");

        // Conditionally add runners based on configuration
        if (!hideSessionsCategory) {
            runners.push("krunner_sessions");
        }

        if (!hidePowerCategory) {
            runners.push("krunner_powerdevil");
        }

        // Add any extra runners from configuration
        if (Plasmoid.configuration.useExtraRunners && Plasmoid.configuration.extraRunners) {
            var extraRunners = Plasmoid.configuration.extraRunners;
            for (var i = 0; i < extraRunners.length; i++) {
                if (runners.indexOf(extraRunners[i]) === -1) {
                    runners.push(extraRunners[i]);
                }
            }
        }

        console.log("Search runners configured:", runners);
        return runners;
    }

    RowLayout
    {
        id: searchComponent
        width: rootItem.resizeWidth() == 0 ? rootItem.calc_width : rootItem.resizeWidth()

        PC3.TextField {
            id: searchField
            visible: rootItem.searchvisible
            Layout.fillWidth: true
            placeholderText: i18n("Type here to search ...")
            topPadding: 10
            bottomPadding: 10
            focus: true
            leftPadding: Kirigami.Units.gridUnit + Kirigami.Units.iconSizes.small
            text: ""
            font.pointSize: Kirigami.Theme.defaultFont.pointSize + 2

            background: Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: Kirigami.Theme.backgroundColor
                border.color: Qt.rgba(0,0,0,0.3)
                border.width: 1
            }

            onTextChanged: {
                kicker.searching = text !== "";
                if (text === "") {
                    runnerModel.query = "";
                } else {
                    runnerModel.query = text;
                    // Keep only apps - as you originally wanted
                    runnerModel.runners = ["krunner_services"];
                }
            }

            // Component initialization with comprehensive search runners
            Component.onCompleted: {
                // Set comprehensive search runners for better app finding
                if (runnerModel) {
                    runnerModel.runners = searchRunners;
                    console.log("Initial search runners set:", searchRunners);
                }
            }

            Keys.onPressed:(event)=>
            {
                kicker.keyIn = "search : " + event.key;
                if(event.modifiers & Qt.ControlModifier ||event.modifiers & Qt.ShiftModifier)
                {
                    focus:true;
                    return;
                }
                else if (event.key === Qt.Key_Tab)
                {
                    event.accepted = true;
                    focus:true;
                }
                else if (event.key === Qt.Key_Escape)
                {
                    event.accepted = true;
                    rootItem.turnclose()
                }
            }

            function backspace()
            {
                if (!kicker.expanded)
                {
                    return;
                }
                focus = true;
                text = text.slice(0, -1);
                if (text=="" || searchField.text == "")
                {
                    searchField.text = "";
                    reset()
                }
            }

            function appendText(newText)
            {
                if (!kicker.expanded)
                {
                    return;
                }
                kicker.searching=true;
                focus = true;
                text = text + newText;
            }

            Kirigami.Icon
            {
                source: 'search'
                anchors
                {
                    left: searchField.left
                    verticalCenter: searchField.verticalCenter
                    leftMargin: Kirigami.Units.smallSpacing * 2
                }
                height: Kirigami.Units.iconSizes.small
                width: height
            }
        }

        Item {Layout.fillWidth: true}

        PC3.ToolButton
        {
            id: btnFavorites
            icon.name: 'favorites'
            visible: rootItem.searchvisible
            flat: !kicker.showFavorites
            onClicked:
            {
                kicker.showFavorites = true
                rootItem.showCategorizedApps = false
                rootItem.showAllAppsView = false
                searchField.text = "";
                rootItem.reset()
            }
            ToolTip.delay: 200
            ToolTip.timeout: 1000
            ToolTip.visible: hovered
            ToolTip.text: i18n("Favorites")
        }

        PC3.ToolButton
        {
            icon.name: "view-list-icons"
            flat: kicker.showFavorites || rootItem.showAllAppsView
            visible: rootItem.searchvisible
            onClicked:
            {
                // Show All Apps view instead of regular grid
                kicker.showFavorites = false
                rootItem.showCategorizedApps = false
                searchField.text = "";
                rootItem.showAllApps(); // Call the enhanced showAllApps function
            }
            ToolTip.delay: 200
            ToolTip.timeout: 1000
            ToolTip.visible: hovered
            ToolTip.text: i18n("All apps")
        }

        // REMOVED: The view switch button is no longer here
        // Users will use Category view by default, and "All apps" button for complete list
    }



    Component.onCompleted: {
        // Set comprehensive search runners for better app finding
        if (runnerModel) {
            runnerModel.runners = searchRunners;
            console.log("Initial search runners set:", searchRunners);
        }
    }

    // Monitor configuration changes
    Connections {
        target: Plasmoid.configuration
        function onUseExtraRunnersChanged() {
            searchRunners = getFilteredSearchRunners();
            if (runnerModel) {
                runnerModel.runners = searchRunners;
            }
        }
        function onExtraRunnersChanged() {
            searchRunners = getFilteredSearchRunners();
            if (runnerModel) {
                runnerModel.runners = searchRunners;
            }
        }
        function onHideAllAppsCategoryChanged() {
            searchRunners = getFilteredSearchRunners();
            if (runnerModel) {
                runnerModel.runners = searchRunners;
            }
        }
        function onHidePowerCategoryChanged() {
            searchRunners = getFilteredSearchRunners();
            if (runnerModel) {
                runnerModel.runners = searchRunners;
            }
        }
        function onHideSessionsCategoryChanged() {
            searchRunners = getFilteredSearchRunners();
            if (runnerModel) {
                runnerModel.runners = searchRunners;
            }
        }
    }

    // Helper functions
    function isRunnerEnabled(runnerId) {
        return searchRunners.includes(runnerId);
    }

    function emptysearch()
    {
        searchField.text = "";
    }

    function backspace()
    {
        searchField.backspace();
    }

    function appendText(p)
    {
        searchField.appendText(p);
    }

    function gofocus()
    {
        searchField.focus = true;
    }
}
