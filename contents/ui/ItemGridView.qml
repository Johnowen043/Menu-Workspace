import QtQuick 2.15
import QtQuick.Layouts 1.1
import org.kde.kquickcontrolsaddons 2.0
import org.kde.ksvg 1.0 as KSvg
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kirigami 2.20 as Kirigami
import QtQuick.Controls 2.15


// This is based on your existing ItemGridView but adds category navigation
FocusScope {
    id: categoryGrid

    signal keyNavLeft
    signal keyNavRight
    signal keyNavUp
    signal keyNavDown
    signal itemActivated(int index, string actionId, string argument)

    property bool dragEnabled: true
    property bool dropEnabled: false
    property bool showLabels: true

    property alias currentIndex: gridView.currentIndex
    property alias currentItem: gridView.currentItem
    property alias contentItem: gridView.contentItem
    property alias contentY: gridView.contentY
    property alias count: gridView.count
    property alias model: gridView.model

    property alias cellWidth: gridView.cellWidth
    property alias cellHeight: gridView.cellHeight
    property alias iconSize: gridView.iconSize
    property alias flow: gridView.flow
    property alias snapMode: gridView.snapMode

    property var horizontalScrollBarPolicy: PlasmaComponents.ScrollBar.AlwaysOff
    property var verticalScrollBarPolicy: PlasmaComponents.ScrollBar.AlwaysOn

    // Category navigation properties
    property var modelStack: []
    property var originalModel: null
    property string currentPath: ""
    property int currentCategoryIndex: -1 // Track selected category for highlighting

    implicitWidth: scrollView.width + (scrollView.ScrollBar.vertical ? scrollView.ScrollBar.vertical.width : 0)
    implicitHeight: scrollView.height

    onDropEnabledChanged: {
        if (!dropEnabled && model && "dropPlaceHolderIndex" in model) {
            model.dropPlaceHolderIndex = -1;
        }
    }

    onFocusChanged: {
        if (!focus) {
            currentIndex = -1;
        }
    }

    // Category navigation functions
    function canGoBack() {
        return modelStack.length > 0;
    }

    function goBack() {
        if (modelStack.length > 0) {
            var previousModel = modelStack.pop();
            gridView.model = previousModel;
            currentIndex = -1;
            currentCategoryIndex = -1; // Clear category selection when going back
            tryActivate(0, 0);

            // Update path
            var pathParts = currentPath.split(" > ");
            pathParts.pop();
            currentPath = pathParts.join(" > ");
        }
    }

    function resetToRoot() {
        if (originalModel) {
            gridView.model = originalModel;
            modelStack = [];
            currentIndex = -1;
            currentCategoryIndex = -1; // Clear category selection when resetting
            currentPath = "";
            tryActivate(0, 0);
        }
    }

    function enterCategory(categoryIndex) {
        if (gridView.model && gridView.model.modelForRow) {
            var categoryModel = gridView.model.modelForRow(categoryIndex);
            if (categoryModel && categoryModel.hasChildren) {
                // Save current model to stack
                modelStack.push(gridView.model);

                // Get category name for path
                var categoryName = "";
                if (gridView.model.data && gridView.model.data(gridView.model.index(categoryIndex, 0))) {
                    categoryName = gridView.model.data(gridView.model.index(categoryIndex, 0)).toString();
                }

                // Update path
                if (currentPath === "") {
                    currentPath = categoryName;
                } else {
                    currentPath = currentPath + " > " + categoryName;
                }

                // Switch to category model
                gridView.model = categoryModel;
                currentIndex = -1;
                tryActivate(0, 0);
                return true;
            }
        }
        return false;
    }

    // Your existing functions - same as ItemGridView
    function currentRow() {
        if (currentIndex === -1) {
            return -1;
        }
        return Math.floor(currentIndex / Math.floor(width / categoryGrid.cellWidth));
    }

    function currentCol() {
        if (currentIndex === -1) {
            return -1;
        }
        return currentIndex - (currentRow() * Math.floor(width / categoryGrid.cellWidth));
    }

    function lastRow() {
        var columns = Math.floor(width / categoryGrid.cellWidth);
        return Math.ceil(count / columns) - 1;
    }

    function tryActivate(row, col) {
        if (count) {
            var columns = Math.floor(width / categoryGrid.cellWidth);
            var rows = Math.ceil(count / columns);
            row = Math.min(row, rows);
            col = Math.min(col, columns);
            currentIndex = Math.min(row ? ((Math.max(1, row) * columns) + col) : col, count - 1);
            kicker.currentRow = row;
            kicker.currentColumn = col;
            kicker.currentIndex = currentIndex;
            focus = true;
        }
    }

    function forceLayout() {
        gridView.forceLayout();
    }

    // Enhanced trigger function with category support
    function trigger(index) {
        if (gridView.model && gridView.model.modelForRow) {
            var itemModel = gridView.model.modelForRow(index);
            if (itemModel && itemModel.hasChildren) {
                // This is a category - enter it
                enterCategory(index);
                return;
            }
        }

        // This is a regular app - trigger it
        if (gridView.model && "trigger" in gridView.model) {
            gridView.model.trigger(index, "", null);
            kicker.expanded = false; // Close menu
        }
    }

    // Your existing ActionMenu - same as original
    ActionMenu {
        id: actionMenu
        onActionClicked: {
            visualParent.actionTriggered(actionId, actionArgument);
        }
    }

    function openActionMenu(x, y, actionList) {
        if (actionList && "length" in actionList && actionList.length > 0) {
            actionMenu.actionList = actionList;
            actionMenu.targetIndex = currentIndex;
            actionMenu.open(x, y);
        }
    }

    // Your existing DropArea - same structure
    DropArea {
        id: dropArea
        anchors.fill: parent
        onPositionChanged: event => {
            if (!categoryGrid.dropEnabled || gridView.animating || !kicker.dragSource) {
                return;
            }

            var x = Math.max(0, event.x - (width % categoryGrid.cellWidth));
            var cPos = mapToItem(gridView.contentItem, x, event.y);
            var item = gridView.itemAt(cPos.x, cPos.y);

            if (item && kicker.dragSource.parent === gridView.contentItem) {
                if (item !== kicker.dragSource && "moveRow" in item.GridView.view.model) {
                    item.GridView.view.model.moveRow(kicker.dragSource.itemIndex, item.itemIndex);
                }
            }
        }

        PlasmaComponents.ScrollView {
            id: scrollView
            anchors.fill: parent
            focus: true

            PlasmaComponents.ScrollBar.horizontal.policy: categoryGrid.horizontalScrollBarPolicy
            PlasmaComponents.ScrollBar.vertical.policy: categoryGrid.verticalScrollBarPolicy

            GridView {
                id: gridView
                anchors.left: parent.left
                anchors.right: parent.right
                width: parent.width > 0 ? parent.width : rootItem.width   // ✅ jamin ada width
                cellWidth: 118
                cellHeight: 100

                implicitHeight: {
                    if (cellHeight <= 0 || cellWidth <= 0) return 0;
                    var gridWidth = width > 0 ? width : 400;  // fallback kalau parent.width 0
                    var cols = Math.max(1, Math.floor(gridWidth / cellWidth));
                    var rows = Math.ceil(count / cols);
                    return rows * cellHeight;
                }

                onCountChanged: {
                    var w = width > 0 ? width : 400
                    var cWidth = cellWidth > 0 ? cellWidth : 100
                    var cols = Math.max(1, Math.floor(w / cWidth))
                    var rows = Math.ceil(count / cols)

                    implicitHeight = rows * cellHeight

                    console.log("SAFE gridView count:", count,
                                "cols:", cols,
                                "rows:", rows,
                                "implicitHeight:", implicitHeight,
                                "width:", w, "cellWidth:", cWidth)
                }

                signal itemContainsMouseChanged(bool containsMouse)

                property int iconSize: Kirigami.Units.iconSizes.huge
                property bool animating: false
                property int animationDuration: categoryGrid.dropEnabled ? 120 : 0

                focus: false
                currentIndex: -1

                keyNavigationWraps: false
                boundsBehavior: Flickable.StopAtBounds

                // Replace the existing highlight section in ItemGridView.qml with this:

                highlight: null

                // Also ensure the delegate uses the enhanced version:
                delegate: ItemGridDelegate {
                    showLabel: categoryGrid.showLabels
                }


                highlightFollowsCurrentItem: false
                highlightMoveDuration: 0

                onCurrentIndexChanged: {
                    if (currentIndex !== -1) {
                        if (hoverArea) {
                            hoverArea.hoverEnabled = false;
                        }
                        focus = true;
                    }
                }

                onModelChanged: {
                    currentIndex = -1;
                    if (!categoryGrid.originalModel) {
                        categoryGrid.originalModel = model;
                    }
                }

                // Your existing key navigation - same as original
                Keys.onPressed: function (event) {
                    if (event.key == Qt.Key_Menu && currentItem && currentItem.hasActionList) {
                        event.accepted = true;
                        openActionMenu(currentItem.x, currentItem.y, currentItem.getActionList());
                        return;
                    }
                    if ((event.key == Qt.Key_Enter || event.key == Qt.Key_Return) && currentIndex != -1) {
                        event.accepted = true;
                        categoryGrid.trigger(currentIndex);
                    }
                }

                onItemContainsMouseChanged: containsMouse => {
                    if (!containsMouse && hoverArea) {
                        hoverArea.pressX = -1;
                        hoverArea.pressY = -1;
                        hoverArea.lastX = -1;
                        hoverArea.lastY = -1;
                        hoverArea.pressedItem = null;
                        hoverArea.hoverEnabled = true;
                    }
                }
            }
        }

        // Your existing MouseArea - enhanced with category support
        MouseArea {
            id: hoverArea
            width: categoryGrid.width - Kirigami.Units.gridUnit
            height: categoryGrid.height

            property int pressX: -1
            property int pressY: -1
            property int lastX: -1
            property int lastY: -1
            property Item pressedItem: null

            acceptedButtons: Qt.LeftButton | Qt.RightButton
            hoverEnabled: enabled

            function updatePositionProperties(x, y) {
                if (lastX === x && lastY === y) {
                    return;
                }
                lastX = x;
                lastY = y;

                var cPos = mapToItem(gridView.contentItem, x, y);
                var index = gridView.indexAt(cPos.x, cPos.y);

                if (index === -1) {
                    gridView.currentIndex = -1;
                    pressedItem = null;
                } else {
                    categoryGrid.focus = true;
                    gridView.currentIndex = index;
                }
                return gridView.itemAtIndex ? gridView.itemAtIndex(index) : null;
            }

            onPressed: mouse => {
                mouse.accepted = true;
                updatePositionProperties(mouse.x, mouse.y);
                pressX = mouse.x;
                pressY = mouse.y;

                if (mouse.button === Qt.RightButton) {
                    if (gridView.currentItem && gridView.currentItem.hasActionList) {
                        var mapped = mapToItem(gridView.currentItem, mouse.x, mouse.y);
                        gridView.currentItem.openActionMenu(mapped.x, mapped.y);
                    }
                } else {
                    pressedItem = gridView.currentItem;
                }
            }

            onReleased: mouse => {
                mouse.accepted = true;
                updatePositionProperties(mouse.x, mouse.y);

                if (typeof dragHelper === 'undefined' || !dragHelper.dragging) {
                    if (pressedItem) {
                        // Use enhanced trigger function with category support
                        categoryGrid.trigger(gridView.currentIndex);
                    } else if (mouse.button === Qt.LeftButton) {
                        // Enhanced empty space click handling
                        if (categoryGrid.canGoBack()) {
                            // Inside a category - go back to main category grid
                            categoryGrid.goBack();
                        } else {
                            // In main category grid - close entire menu
                            kicker.expanded = false;
                        }
                    }
                }
                pressX = pressY = -1;
                pressedItem = null;
            }

            onPressAndHold: mouse => {
                if (!dragEnabled) {
                    pressX = -1;
                    pressY = -1;
                    return;
                }

                var cPos = mapToItem(gridView.contentItem, mouse.x, mouse.y);
                var item = gridView.itemAt(cPos.x, cPos.y);

                if (!item) {
                    return;
                }

                if (typeof dragHelper !== 'undefined' && !dragHelper.isDrag(pressX, pressY, mouse.x, mouse.y)) {
                    kicker.dragSource = item;
                    dragHelper.startDrag(kicker, item.url);
                }

                pressX = -1;
                pressY = -1;
            }

            onPositionChanged: mouse => {
                var item = pressedItem ? pressedItem : updatePositionProperties(mouse.x, mouse.y);

                if (gridView.currentIndex !== -1) {
                    if (categoryGrid.dragEnabled && pressX !== -1
                        && typeof dragHelper !== 'undefined' && dragHelper.isDrag(pressX, pressY, mouse.x, mouse.y)) {
                        if (currentItem && currentItem.m && "pluginName" in currentItem.m) {
                            dragHelper.startDrag(kicker, currentItem.url, currentItem.icon,
                                                 "text/x-plasmoidservicename", currentItem.m.pluginName);
                        } else if (currentItem) {
                            dragHelper.startDrag(kicker, currentItem.url);
                        }

                        kicker.dragSource = currentItem;
                    pressX = -1;
                    pressY = -1;
                        }
                }
            }
        }
    }
}
