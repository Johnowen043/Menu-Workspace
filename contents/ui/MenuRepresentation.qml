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

FocusScope
{
    id: rootItem
    property bool showGridFirst: Plasmoid.configuration.showGridFirst
    property bool searchvisible : Plasmoid.configuration.showSearch

    // DEFAULT TO CATEGORY VIEW (categories are the primary navigation)
    property bool showCategorizedApps: Plasmoid.configuration.showCategorizedApps !== undefined ? Plasmoid.configuration.showCategorizedApps : true

    // Add property to control "All Apps" display (flat list of all applications)
    property bool showAllAppsView: false

    property int visible_items: (Plasmoid.configuration.showInfoUser ? headingSvg.height : 0) + (rootItem.searchvisible == true ? rowSearchField.height : 0) + ( kicker.view_any_controls == true ? footer.height : 0)+ Kirigami.Units.gridUnit
    property int cuadricula_hg : (kicker.cellSizeHeight *  Plasmoid.configuration.numberRows)
    property int calc_width : (kicker.cellSizeWidth *  Plasmoid.configuration.numberColumns) + Kirigami.Units.gridUnit
    property int calc_height : cuadricula_hg  + (rootItem.visible_items)
    property int userShape : calculateUserShape(Plasmoid.configuration.userShape);
    property int space_width : resizeWidth()  == 0 ? rootItem.calc_width : resizeWidth()
    property int space_height : resizeHeight() == 0 ? rootItem.calc_height  : resizeHeight()
    property int dynamicColumns : Math.floor( rootItem.space_width  / kicker.cellSizeWidth)
    property int dynamicRows : Math.ceil(kicker.count / dynamicColumns)

    Layout.maximumWidth: space_width
    Layout.minimumWidth: space_width
    Layout.minimumHeight:space_height
    Layout.maximumHeight:space_height
    focus: true

    KCoreAddons.KUser { id: kuser }
    Logic { id: logic }

    //graphics
    KSvg.FrameSvgItem
    {
        id : headingSvg
        width: parent.width + backgroundSvg.margins.left + backgroundSvg.margins.right
        height: Plasmoid.configuration.showInfoUser ? encabezado.height + Kirigami.Units.smallSpacing : Kirigami.Units.smallSpacing
        y: - backgroundSvg.margins.top
        x: - backgroundSvg.margins.left
        imagePath: "widgets/plasmoidheading"
        prefix: "header"
        opacity: Plasmoid.configuration.transparencyHead * 0.01
        visible: Plasmoid.configuration.showInfoUser
    }

    KSvg.FrameSvgItem
    {
        id: footerSvg
        visible: kicker.view_any_controls
        width: parent.width + backgroundSvg.margins.left + backgroundSvg.margins.right
        height:footer.Layout.preferredHeight + 2  + Kirigami.Units.smallSpacing * 3
        y: parent.height + Kirigami.Units.smallSpacing * 2
        x: backgroundSvg.margins.left
        imagePath: "widgets/plasmoidheading"
        prefix: "header"
        transform: Rotation { angle: 180; origin.x: width / 2;}
        opacity: Plasmoid.configuration.transparencyFooter * 0.01
    }

    //contenedor del menu
    ColumnLayout
    {
        id:container
        Layout.preferredHeight: rootItem.space_height
        //encabezado
        Item
        {
            id: encabezado
            width: rootItem.space_width
            Layout.preferredHeight: 130
            visible:  Plasmoid.configuration.showInfoUser
            Loader
            {
                id: head_
                sourceComponent: headComponent
                onLoaded:
                {
                    var pinButton = head_.item.pinButton;
                    if (!activeFocus && kicker.hideOnWindowDeactivate === false)
                    {
                        if (!pinButton.checked) {turnclose();}
                    }
                }
            }
        }
        //cuadrilla
        Item
        {
            id: gridComponent
            width: rootItem.space_width
            Layout.preferredHeight:(resizeHeight() == 0 ? rootItem.cuadricula_hg  : resizeHeight() -rootItem.visible_items)

            //cuadrilla para favoritos - ENHANCED WITH PROPER FAVORITES MODEL
            ItemGridView
            {
                id: globalFavoritesGrid
                visible: (Plasmoid.configuration.showFavoritesFirst || kicker.showFavorites) && (!kicker.searching && kicker.showFavorites) && !rootItem.showCategorizedApps && !rootItem.showAllAppsView
                dragEnabled: true
                dropEnabled: true
                height: rootItem.resizeHeight() == 0 ? rootItem.cuadricula_hg  : rootItem.resizeHeight() - rootItem.visible_items
                width: rootItem.width
                focus: true
                cellWidth:   kicker.cellSizeWidth
                cellHeight:  kicker.cellSizeHeight
                iconSize:    kicker.iconSize
                model: globalFavorites  // Use the proper favorites model
                onKeyNavUp:  searchLoader.item.gofocus();
                Keys.onPressed:(event)=>
                {
                    kicker.keyIn = "favoritos : " + event.key;
                    if(event.modifiers & Qt.ControlModifier ||event.modifiers & Qt.ShiftModifier)
                    {
                        searchLoader.item.gofocus();
                        return
                    }
                    else if (event.key === Qt.Key_Tab)
                    {
                        event.accepted = true;
                        searchLoader.item.gofocus();
                    }
                    else if (event.key === Qt.Key_Escape)
                    {
                        event.accepted = true;
                        rootItem.turnclose()
                    }
                }
            }

            // CATEGORY GRID - DEFAULT VIEW (Now visible by default) with enhanced mouse handling
            AppsGridView {
                id: categoryGrid
                visible: rootItem.showCategorizedApps && !kicker.searching && !rootItem.showAllAppsView
                enabled: visible
                focus: visible

                width: rootItem.width
                height: visible ? (
                    rootItem.resizeHeight() == 0
                    ? rootItem.cuadricula_hg
                    : rootItem.resizeHeight()
                    - (footer.visible ? footer.height : 0)
                    - (rowSearchField.visible ? rowSearchField.height : 0)
                ) : 0
                cellWidth: kicker.cellSizeWidth
                iconSize: kicker.iconSize

                model: rootModel

                onKeyNavUp: searchLoader.item.gofocus()

                Keys.onPressed: (event) => {
                    kicker.keyIn = "category grid : " + event.key;
                    if(event.modifiers & Qt.ControlModifier ||event.modifiers & Qt.ShiftModifier)
                    {
                        searchLoader.item.gofocus();
                        return
                    }
                    else if (event.key === Qt.Key_Tab)
                    {
                        event.accepted = true;
                        searchLoader.item.gofocus();
                    }
                    else if (event.key === Qt.Key_Escape)
                    {
                        event.accepted = true;
                        if (categoryGrid.canGoBack()) {
                            categoryGrid.goBack();
                        } else {
                            rootItem.turnclose();
                        }
                    }
                    else if (event.key === Qt.Key_Backspace)
                    {
                        event.accepted = true;
                        if(!kicker.searching && categoryGrid.canGoBack()){
                            categoryGrid.goBack();
                        } else if(kicker.searching){
                            searchLoader.item.backspace();
                            searchLoader.item.gofocus();
                        } else {
                            searchLoader.item.gofocus();
                        }
                    }
                    else if (event.text !== "")
                    {
                        event.accepted = true;
                        searchLoader.item.appendText(event.text);
                    }
                }
            }

            // ALL APPS GRID - Shows complete flat application list with enhanced mouse handling
            ItemGridView
            {
                id: allAppsCompleteGrid
                visible: rootItem.showAllAppsView && !kicker.searching
                enabled: visible
                focus: visible

                width: rootItem.width
                height: rootItem.resizeHeight() == 0 ? rootItem.cuadricula_hg  : rootItem.resizeHeight() - rootItem.visible_items
                cellWidth:   kicker.cellSizeWidth
                cellHeight:  kicker.cellSizeHeight
                iconSize:    kicker.iconSize
                dropEnabled: false
                dragEnabled: false

                onKeyNavUp: searchLoader.item.gofocus()

                Keys.onPressed:(event)=>
                {
                    kicker.keyIn = "all apps complete : " + event.key;
                    if(event.modifiers & Qt.ControlModifier ||event.modifiers & Qt.ShiftModifier)
                    {
                        searchLoader.item.gofocus();
                        return;
                    }
                    if (event.key === Qt.Key_Tab)
                    {
                        event.accepted = true;
                        searchLoader.item.gofocus();
                    }
                    else if (event.key === Qt.Key_Backspace)
                    {
                        event.accepted = true;
                        if(kicker.searching){searchLoader.item.backspace();}
                        searchLoader.item.gofocus();
                    }
                    else if (event.key === Qt.Key_Escape)
                    {
                        event.accepted = true;
                        if(kicker.searching){rootItem.reset()}
                        else {
                            // Go back to default category view
                            rootItem.goBackToCategoryView();
                        }
                    }
                    else if (event.text !== "")
                    {
                        event.accepted = true;
                        searchLoader.item.appendText(event.text);
                    }
                }

                // Enhanced mouse area for blank space clicking
                MouseArea {
                    id: allAppsMouseArea
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton
                    propagateComposedEvents: true
                    z: -1  // Behind the grid items

                    onClicked: function(mouse) {
                        // Check if we clicked on empty space (not on an item)
                        var cPos = mapToItem(allAppsCompleteGrid.contentItem, mouse.x, mouse.y);
                        var item = allAppsCompleteGrid.itemAt(cPos.x, cPos.y);

                        if (!item) {
                            // Clicked on empty space - go back to category view
                            rootItem.goBackToCategoryView();
                        } else {
                            // Allow the click to propagate to the item
                            mouse.accepted = false;
                        }
                    }
                }
            }

            Item {
                id: mainGrids
                visible: kicker.searching || (!Plasmoid.configuration.showFavoritesFirst && !kicker.showFavorites && !rootItem.showCategorizedApps && !rootItem.showAllAppsView)
                width: rootItem.width

                Item
                {
                    id: mainColumn
                    width: rootItem.width
                    property Item visibleGrid: allAppsGrid

                    ItemGridView
                    {
                        id: allAppsGrid
                        width: rootItem.width > 0 ? rootItem.width : parent.width > 0 ? parent.width : 400
                        height: rootItem.resizeHeight() == 0 ? rootItem.cuadricula_hg  : rootItem.resizeHeight() - rootItem.visible_items
                        cellWidth:   kicker.cellSizeWidth
                        cellHeight:  kicker.cellSizeHeight
                        iconSize:    kicker.iconSize
                        enabled: (opacity == 1) ? 1 : 0
                        z:  enabled ? 5 : -1
                        dropEnabled: false
                        dragEnabled: false
                        opacity: kicker.searching ? 0 : 1
                        onOpacityChanged: { if (opacity == 1) { mainColumn.visibleGrid = allAppsGrid; } }
                        onKeyNavUp: searchLoader.item.gofocus()
                    }

                    ItemMultiGridView {
                        id: runnerGrid
                        width: rootItem.width > 0 ? rootItem.width : parent.width > 0 ? parent.width : 400
                        visible: kicker.searching
                        enabled: visible
                        focus: visible

                        // pakai manual height fallback
                        height: visible
                        ? Math.max(
                            (rootItem.resizeHeight() === 0
                            ? rootItem.cuadricula_hg
                            : rootItem.resizeHeight()
                            - ((rowSearchField && rowSearchField.visible ? rowSearchField.height : 0)
                            + (footer && footer.visible ? footer.height : 0)
                            + Kirigami.Units.gridUnit)),
                            200 // fallback minimal supaya ga drop ke 0
                        )
                        : 0

                        implicitHeight: height

                        cellWidth: kicker.cellSizeWidth
                        cellHeight: kicker.cellSizeHeight
                        model: runnerModel

                        z: visible ? 5 : -1
                        opacity: visible ? 1.0 : 0.0

                        onOpacityChanged: {
                            if (opacity === 1.0) {
                                mainColumn.visibleGrid = runnerGrid;
                            }
                        }

                        onHeightChanged: {
                            console.log("DEBUG runnerGrid FINAL:",
                                        "height=", height,
                                        "resizeHeight=", rootItem.resizeHeight(),
                                        "rowSearchField=", rowSearchField ? rowSearchField.height : -1,
                                        "footer=", footer ? footer.height : -1,
                                        "contentHeight=", contentHeight,
                                        "modelCount=", runnerModel ? runnerModel.count : -1)
                        }
                    }


                    function tryActivate(row, col) {
                        if (visibleGrid) {
                            visibleGrid.tryActivate(row, col);
                        }
                    }

                    Keys.onPressed: (event)=>
                    {
                        kicker.keyIn = "cuadrilla o busqueda : " + event.key;
                        if(event.modifiers & Qt.ControlModifier ||event.modifiers & Qt.ShiftModifier)
                        {
                            searchLoader.item.gofocus();
                            return;
                        }
                        if (event.key === Qt.Key_Tab)
                        {
                            event.accepted = true;
                            searchLoader.item.gofocus();
                        }
                        else if (event.key === Qt.Key_Backspace)
                        {
                            event.accepted = true;
                            if(kicker.searching){searchLoader.item.backspace();}
                            searchLoader.item.gofocus();
                        }
                        else if (event.key === Qt.Key_Escape)
                        {
                            event.accepted = true;
                            if(kicker.searching){rootItem.reset()}
                            else {rootItem.turnclose();}
                        }
                        else if (event.text !== "")
                        {
                            event.accepted = true;
                            searchLoader.item.appendText(event.text);
                        }
                    }
                }
            }
        }
        //buscador
        Item
        {
            id: rowSearchField
            visible: rootItem.searchvisible
            Layout.preferredHeight:45
            width: rootItem.space_width
            Loader{
                id: searchLoader
                sourceComponent: searchComponent
            }
        }
        //controles
        Item
        {
            id: footer
            Layout.preferredHeight:25
            visible: kicker.view_any_controls
            width: rootItem.space_width
            Loader
            {
                id: foot_
                sourceComponent: footerComponent
            }
        }
    }

    Keys.onPressed: (event)=>
    {
        kicker.keyIn = "menurepresentation : " + event.key;
        event.accepted = true;
        if (event.modifiers & (Qt.ControlModifier | Qt.ShiftModifier)) {
            searchLoader.item.gofocus();
            return;
        }
        switch (event.key)
        {
            case Qt.Key_Escape:
                if (rootItem.showAllAppsView) {
                    rootItem.goBackToCategoryView();
                } else if (rootItem.showCategorizedApps && categoryGrid.canGoBack()) {
                    categoryGrid.goBack();
                } else {
                    turnclose();
                }
                break;
            case Qt.Key_Backspace:
                if (rootItem.showAllAppsView) {
                    rootItem.goBackToCategoryView();
                } else if (rootItem.showCategorizedApps && categoryGrid.canGoBack()) {
                    categoryGrid.goBack();
                } else {
                    searchLoader.item.backspace();
                }
                break;
            case Qt.Key_Tab:
            case Qt.Key_Backtab:
            case Qt.Key_Down:
            case Qt.Key_Up:
            case Qt.Key_Left:
            case Qt.Key_Enter:
            case Qt.Key_Return:
            case Qt.Key_Right:
                reset();
                break;
            default:
                if (isLetterOrNumber(event.text))
                {
                    searchLoader.item.appendText(event.text);
                }
                else {
                    reset();
                }
                break;
        }
        searchLoader.item.gofocus();
    }

    // ENHANCED All Apps function - uses dedicated flat model for comprehensive app list
    function showAllApps() {
        console.log("Switching to All Apps view...");

        // Switch view states
        rootItem.showAllAppsView = true;
        rootItem.showCategorizedApps = false;
        kicker.showFavorites = false;
        kicker.searching = false;

        // Clear search if active
        if (searchLoader.item) {
            searchLoader.item.emptysearch();
        }

        // Use the dedicated flat apps model for comprehensive application list
        var allAppsModel = null;

        // Method 1: Use the dedicated flat model from main.qml
        if (kicker.allAppsModel && kicker.allAppsModel.count > 0) {
            // Get the first model from the flat model which contains all apps
            allAppsModel = kicker.allAppsModel.modelForRow(0);
        }

        // Method 2: Fallback to creating a temporary flat model
        if (!allAppsModel || (allAppsModel && allAppsModel.count === 0)) {
            // Create a temporary root model with all apps enabled
            var tempRootModel = Qt.createQmlObject(`
            import org.kde.plasma.private.kicker 0.1 as Kicker;
            Kicker.RootModel {
                autoPopulate: false
                appNameFormat: 0
                flat: true
                sorted: true
                showSeparators: false
                showAllApps: true
                showRecentApps: false
                showRecentDocs: false
                showPowerSession: false
                Component.onCompleted: refresh()
            }
            `, rootItem);

            if (tempRootModel && tempRootModel.count > 0) {
                allAppsModel = tempRootModel.modelForRow(0);
            }
        }

        // Method 3: Search through rootModel for the largest application category
        if (!allAppsModel || (allAppsModel && allAppsModel.count === 0)) {
            var largestModel = null;
            var largestCount = 0;

            for (var i = 0; i < rootModel.count; i++) {
                var categoryModel = rootModel.modelForRow(i);
                if (categoryModel && categoryModel.count > largestCount) {
                    // Check if this category contains applications by examining the first item
                    var testItem = categoryModel.data(categoryModel.index(0, 0), Qt.DisplayRole);
                    if (testItem) {
                        largestModel = categoryModel;
                        largestCount = categoryModel.count;
                    }
                }
            }

            if (largestModel) {
                allAppsModel = largestModel;
            }
        }

        // Method 4: Use existing allAppsGrid model
        if (!allAppsModel && allAppsGrid.model) {
            allAppsModel = allAppsGrid.model;
        }

        // Method 5: Last resort - use rootModel
        if (!allAppsModel) {
            allAppsModel = rootModel;
        }

        // Set the model
        if (allAppsModel) {
            allAppsCompleteGrid.model = allAppsModel;
        }

        // Focus the All Apps grid
        allAppsCompleteGrid.focus = true;
        allAppsCompleteGrid.tryActivate(0, 0);
    }

    // Function to go back from All Apps view to category view
    function exitAllAppsView() {
        rootItem.showAllAppsView = false;
        rootItem.showCategorizedApps = true; // Go back to category view (default)
        categoryGrid.focus = true;
        categoryGrid.tryActivate(0, 0);
    }

    //component
    Component {id: footerComponent; Footer{}}
    Component {id: searchComponent; Search{}}
    Component {id: headComponent; Head{}}

    //functions
    function isLetterOrNumber(text) {
        return /^[a-zA-Z0-9]$/.test(text);
    }

    function turnclose()
    {
        searchLoader.item.emptysearch()
        kicker.searching=false;

        // Always reset to category view when closing menu
        if (rootItem.showAllAppsView) {
            rootItem.showAllAppsView = false;
            rootItem.showCategorizedApps = true;
        }

        // Reset any category navigation
        if (rootItem.showCategorizedApps) {
            categoryGrid.resetToRoot();
            categoryGrid.tryActivate(0,0);
        }
        else if (kicker.showFavorites) {globalFavoritesGrid.tryActivate(0,0);}
        else {mainColumn.tryActivate(0,0);}

        kicker.expanded = false;
        return
    }

    function reset()
    {
        searchLoader.item.emptysearch()
        kicker.searching=false;
        if (rootItem.showAllAppsView) {
            allAppsCompleteGrid.tryActivate(0,0);
        } else if (rootItem.showCategorizedApps) {
            categoryGrid.tryActivate(0,0);
        }
        else if (kicker.showFavorites) {globalFavoritesGrid.tryActivate(0,0);}
        else {mainColumn.tryActivate(0,0);}
    }

    // Function to go back to category view from All Apps
    function goBackToCategoryView() {
        rootItem.showAllAppsView = false;
        rootItem.showCategorizedApps = true;
        kicker.showFavorites = false;
        categoryGrid.resetToRoot();
        categoryGrid.focus = true;
        categoryGrid.tryActivate(0, 0);
    }

    function resizeWidth()
    {
        var screenAvail = kicker.availableScreenRect;
        var screenGeom = kicker.screenGeometry;
        var screen = Qt.rect(screenAvail.x + screenGeom.x,screenAvail.y + screenGeom.y,screenAvail.width, screenAvail.height);
        if (screen.width > (kicker.cellSizeWidth *  Plasmoid.configuration.numberColumns) + Kirigami.Units.gridUnit){
            return 0;
        } else {
            return screen.width - Kirigami.Units.gridUnit * 2 ;
        }
    }

    function resizeHeight()
    {
        var screenAvail = kicker.availableScreenRect;
        var screenGeom = kicker.screenGeometry;
        var screen = Qt.rect(screenAvail.x + screenGeom.x,screenAvail.y + screenGeom.y,screenAvail.width, screenAvail.height);
        if (screen.height > (kicker.cellSizeHeight *  Plasmoid.configuration.numberRows) + rootItem.visible_items + Kirigami.Units.gridUnit * 1.5) {
            return 0;
        } else {
            return screen.height - Kirigami.Units.gridUnit * 2;
        }
    }

    function updateLayouts()
    {
        rootItem.searchvisible = Plasmoid.configuration.showSearch;
        rootItem.showCategorizedApps = Plasmoid.configuration.showCategorizedApps !== undefined ? Plasmoid.configuration.showCategorizedApps : true;
        rootItem.visible_items = (Plasmoid.configuration.showInfoUser ? headingSvg.height : 0) + (rootItem.searchvisible == true ? rowSearchField.height : 0) + ( kicker.view_any_controls == true ? footer.height : 0)+ Kirigami.Units.gridUnit
        rootItem.cuadricula_hg = (kicker.cellSizeHeight *  Plasmoid.configuration.numberRows);
        rootItem.calc_width = (kicker.cellSizeWidth *  Plasmoid.configuration.numberColumns) + Kirigami.Units.gridUnit;
        rootItem.calc_height = rootItem.cuadricula_hg  + rootItem.visible_items;
        rootItem.userShape = calculateUserShape(Plasmoid.configuration.userShape);
        kicker.keyIn="me actualice";
    }

    function calculateUserShape(shape)
    {
        switch (shape) {
            case 0: return (kicker.sizeImage * 0.85) / 2;
            case 1: return 8;
            case 2: return 0;
            default:return (kicker.sizeImage * 0.85) / 2;
        }
    }

    function setModels()
    {
        // Enhanced model setting with proper favorites handling
        globalFavoritesGrid.model = globalFavorites;

        // Set up the regular apps grid with the first available model
        if (rootModel && rootModel.count > 0) {
            allAppsGrid.model = rootModel.modelForRow(0);
        }

        // Initialize the all apps complete grid with the flat model
        if (kicker.allAppsModel && kicker.allAppsModel.count > 0) {
            var flatModel = kicker.allAppsModel.modelForRow(0);
            if (flatModel) {
                allAppsCompleteGrid.model = flatModel;
            }
        }

        // Ensure favorites are properly loaded
        if (globalFavorites && globalFavorites.favorites) {
            // Favorites loaded successfully
        }
    }

    onActiveFocusChanged:
    {
        if (!activeFocus && kicker.hideOnWindowDeactivate === false)
        {
            if (head_.item && head_.item.pinButton) {
                if (!head_.item.pinButton.checked) {
                    turnclose();
                }
            }
        }
    }

    Component.onCompleted:
    {
        rootModel.refreshed.connect(setModels)
        rootModel.refresh();

        // DEFAULT TO CATEGORY VIEW
        if (rootItem.showCategorizedApps) {
            categoryGrid.tryActivate(0,0);
        }
        else if (kicker.showFavorites) {
            globalFavoritesGrid.tryActivate(0,0);
        } else {
            mainColumn.tryActivate(0,0);
        }
    }
}
