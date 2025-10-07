import QtQuick 2.15

import org.kde.kquickcontrolsaddons 2.0
import org.kde.ksvg 1.0 as KSvg
import org.kde.plasma.components as PlasmaComponents
import org.kde.plasma.extras 2.0 as PlasmaExtras
import org.kde.kirigami 2.20 as Kirigami

FocusScope {
    id: categoryItemGrid

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
    property int cellHeight: cellWidth
    property alias iconSize: gridView.iconSize

    property alias flow: gridView.flow
    property alias snapMode: gridView.snapMode

    // ✅ CHANGED: Default scrollbar policies to AlwaysOff
    property var horizontalScrollBarPolicy: PlasmaComponents.ScrollBar.AlwaysOff
    property var verticalScrollBarPolicy: PlasmaComponents.ScrollBar.AlwaysOff  // This was AlwaysOn before!

    property var modelStack: []
    property var originalModel: null

    implicitWidth: scrollView ? scrollView.width : (parent ? parent.width : 400)
    implicitHeight: scrollView ? scrollView.height : 200

    onDropEnabledChanged: {
        if (!dropEnabled && "dropPlaceHolderIndex" in model) {
            model.dropPlaceHolderIndex = -1;
        }
    }

    onFocusChanged: {
        if (!focus) {
            currentIndex = -1;
        }
    }

    function canGoBack() {
        return modelStack.length > 0;
    }

    function goBack() {
        if (modelStack.length > 0) {
            gridView.model = modelStack.pop();
            currentIndex = -1;
        }
    }

    function resetToRoot() {
        if (originalModel) {
            gridView.model = originalModel;
            modelStack = [];
            currentIndex = -1;
        }
    }

    function enterDirectory(directoryIndex) {
        if (gridView.model && gridView.model.modelForRow) {
            var dirModel = gridView.model.modelForRow(directoryIndex);
            if (dirModel && dirModel.hasChildren) {
                modelStack.push(gridView.model);
                gridView.model = dirModel;
                currentIndex = -1;
                tryActivate(0, 0);
            }
        }
    }

    function currentRow() {
        if (currentIndex === -1) {
            return -1;
        }
        return Math.floor(currentIndex / Math.floor(width / categoryItemGrid.cellWidth));
    }

    function currentCol() {
        if (currentIndex === -1) {
            return -1;
        }
        return currentIndex - (currentRow() * Math.floor(width / categoryItemGrid.cellWidth));
    }

    function lastRow() {
        var columns = Math.floor(width / categoryItemGrid.cellWidth);
        return Math.ceil(count / columns) - 1;
    }

    function tryActivate(row, col) {
        if (count) {
            var columns = Math.floor(width / categoryItemGrid.cellWidth);
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

    function trigger(index) {
        if (index === -1 || index >= count) {
            if (canGoBack()) {
                goBack();
            } else {
                kicker.expanded = false;
            }
            return;
        }

        var item = gridView.model;
        if (item && item.modelForRow) {
            var dirModel = item.modelForRow(index);
            if (dirModel && dirModel.hasChildren) {
                enterDirectory(index);
                return;
            }
        }

        if ("trigger" in gridView.model) {
            gridView.model.trigger(index, "", null);
            kicker.expanded = false;
        }
    }

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

    DropArea {
        id: dropArea
        anchors.fill: parent

        onPositionChanged: event => {
            if (!categoryItemGrid.dropEnabled || gridView.animating || !kicker.dragSource) {
                return;
            }

            var x = Math.max(0, event.x - (width % categoryItemGrid.cellWidth));
            var cPos = mapToItem(gridView.contentItem, x, event.y);
            var item = gridView.itemAt(cPos.x, cPos.y);

            if (item) {
                if (kicker.dragSource.parent === gridView.contentItem) {
                    if (item !== kicker.dragSource) {
                        item.GridView.view.model.moveRow(dragSource.itemIndex, item.itemIndex);
                    }
                } else if (kicker.dragSource.GridView.view.model.favoritesModel === categoryItemGrid.model
                    && !categoryItemGrid.model.isFavorite(kicker.dragSource.favoriteId)) {
                    var hasPlaceholder = (categoryItemGrid.model.dropPlaceholderIndex !== -1);

                categoryItemGrid.model.dropPlaceholderIndex = item.itemIndex;

                if (!hasPlaceholder) {
                    gridView.currentIndex = (item.itemIndex - 1);
                }
                    }
            } else if (kicker.dragSource.parent !== gridView.contentItem
                && kicker.dragSource.GridView.view.model.favoritesModel === categoryItemGrid.model
                && !categoryItemGrid.model.isFavorite(kicker.dragSource.favoriteId)) {
                var hasPlaceholder = (categoryItemGrid.model.dropPlaceholderIndex !== -1);

            categoryItemGrid.model.dropPlaceholderIndex = hasPlaceholder ? categoryItemGrid.model.count - 1 : categoryItemGrid.model.count;

            if (!hasPlaceholder) {
                gridView.currentIndex = (categoryItemGrid.model.count - 1);
            }
                } else {
                    categoryItemGrid.model.dropPlaceholderIndex = -1;
                    gridView.currentIndex = -1;
                }
        }

        onExited: {
            if ("dropPlaceholderIndex" in categoryItemGrid.model) {
                categoryItemGrid.model.dropPlaceholderIndex = -1;
                gridView.currentIndex = -1;
            }
        }

        onDropped: {
            if (kicker.dragSource && kicker.dragSource.parent !== gridView.contentItem
                && kicker.dragSource.GridView.view.model.favoritesModel === categoryItemGrid.model) {
                categoryItemGrid.model.addFavorite(kicker.dragSource.favoriteId, categoryItemGrid.model.dropPlaceholderIndex);
            gridView.currentIndex = -1;
                }
        }

        Timer {
            id: resetAnimationDurationTimer
            interval: 120
            repeat: false
            onTriggered: {
                gridView.animationDuration = interval - 20;
            }
        }

        PlasmaComponents.ScrollView {
            id: scrollView
            anchors.fill: parent
            focus: true

            // ✅ EXPLICIT SCROLLBAR POLICY OVERRIDE
            PlasmaComponents.ScrollBar.horizontal.policy: PlasmaComponents.ScrollBar.AlwaysOff
            PlasmaComponents.ScrollBar.vertical.policy: PlasmaComponents.ScrollBar.AlwaysOff

            GridView {
                id: gridView
                anchors.fill: parent

                implicitHeight: {
                    var w = width > 0 ? width : 400;
                    var cW = cellWidth > 0 ? cellWidth : 120;
                    var cH = cellHeight > 0 ? cellHeight : (cW);
                    var cols = Math.max(1, Math.floor(w / cW));
                    var rows = Math.ceil(count / cols);
                    return rows * cH;
                }

                height: implicitHeight

                signal itemContainsMouseChanged(bool containsMouse)

                property int iconSize: Kirigami.Units.iconSizes.huge
                property bool animating: false
                property int animationDuration: categoryItemGrid.dropEnabled ? resetAnimationDurationTimer.interval : 0

                focus: true
                currentIndex: -1

                cellHeight: cellWidth

                move: Transition {
                    enabled: categoryItemGrid.dropEnabled
                    SequentialAnimation {
                        PropertyAction { target: gridView; property: "animating"; value: true }
                        NumberAnimation {
                            duration: gridView.animationDuration
                            properties: "x, y"
                            easing.type: Easing.OutQuad
                        }
                        PropertyAction { target: gridView; property: "animating"; value: false }
                    }
                }

                moveDisplaced: Transition {
                    enabled: categoryItemGrid.dropEnabled
                    SequentialAnimation {
                        PropertyAction { target: gridView; property: "animating"; value: true }
                        NumberAnimation {
                            duration: gridView.animationDuration
                            properties: "x, y"
                            easing.type: Easing.OutQuad
                        }
                        PropertyAction { target: gridView; property: "animating"; value: false }
                    }
                }

                keyNavigationWraps: false
                boundsBehavior: Flickable.StopAtBounds

                delegate: ItemGridDelegate {
                    showLabel: categoryItemGrid.showLabels
                }

                highlight: null
                highlightFollowsCurrentItem: false
                highlightMoveDuration: 0

                onCurrentIndexChanged: {
                    if (currentIndex !== -1 && hoverArea) {
                        hoverArea.hoverEnabled = false
                        focus = true;
                    }
                }

                onCountChanged: {
                    animationDuration = 0;
                    resetAnimationDurationTimer.start();
                }

                onModelChanged: {
                    currentIndex = -1;
                    if (!categoryItemGrid.originalModel) {
                        categoryItemGrid.originalModel = model;
                    }
                }

                Keys.onLeftPressed: function (event) {
                    if (currentIndex == -1) {
                        currentIndex = 0;
                        return;
                    }
                    if (!(event.modifiers & Qt.ControlModifier) && currentCol() != 0) {
                        event.accepted = true;
                        moveCurrentIndexLeft();
                    } else {
                        categoryItemGrid.keyNavLeft();
                    }
                }

                Keys.onRightPressed: function (event) {
                    if (currentIndex == -1) {
                        currentIndex = 0;
                        return;
                    }
                    var columns = Math.floor(width / cellWidth);
                    if (!(event.modifiers & Qt.ControlModifier) && currentCol() != columns - 1 && currentIndex != count - 1) {
                        event.accepted = true;
                        moveCurrentIndexRight();
                    } else {
                        categoryItemGrid.keyNavRight();
                    }
                }

                Keys.onUpPressed: function (event) {
                    if (currentIndex == -1) {
                        currentIndex = 0;
                        return;
                    }
                    if (currentRow() != 0) {
                        event.accepted = true;
                        moveCurrentIndexUp();
                        positionViewAtIndex(currentIndex, GridView.Contain);
                    } else {
                        categoryItemGrid.keyNavUp();
                    }
                }

                Keys.onDownPressed: function (event) {
                    if (currentIndex == -1) {
                        currentIndex = 0;
                        return;
                    }
                    if (currentRow() < categoryItemGrid.lastRow()) {
                        event.accepted = true;
                        var columns = Math.floor(width / cellWidth);
                        var newIndex = currentIndex + columns;
                        currentIndex = Math.min(newIndex, count - 1);
                        positionViewAtIndex(currentIndex, GridView.Contain);
                    } else {
                        categoryItemGrid.keyNavDown();
                    }
                }

                Keys.onPressed: function (event) {
                    if (event.key == Qt.Key_Menu && currentItem && currentItem.hasActionList) {
                        event.accepted = true;
                        openActionMenu(currentItem.x, currentItem.y, currentItem.getActionList());
                        return;
                    }
                    if ((event.key == Qt.Key_Enter || event.key == Qt.Key_Return) && currentIndex != -1) {
                        event.accepted = true;
                        categoryItemGrid.trigger(currentIndex);
                    }

                    let rowsInPage = Math.floor(gridView.height / cellHeight);

                    if (event.key == Qt.Key_PageUp) {
                        if (currentIndex == -1) {
                            currentIndex = 0;
                            return;
                        }
                        if (currentRow() != 0) {
                            event.accepted = true;
                            tryActivate(currentRow() - rowsInPage, currentCol());
                            positionViewAtIndex(currentIndex, GridView.Beginning);
                        } else {
                            categoryItemGrid.keyNavUp();
                        }
                        return;
                    }

                    if (event.key == Qt.Key_PageDown) {
                        if (currentIndex == -1) {
                            currentIndex = 0;
                            return;
                        }
                        if (currentRow() != numberRows - 1) {
                            event.accepted = true;
                            tryActivate(currentRow() + rowsInPage, currentCol());
                            positionViewAtIndex(currentIndex, GridView.Beginning);
                        } else {
                            categoryItemGrid.keyNavDown();
                        }
                        return;
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

        MouseArea {
            id: hoverArea
            anchors.fill: parent

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
                    categoryItemGrid.focus = true;
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
                    if (gridView.currentItem) {
                        if (gridView.currentItem.hasActionList) {
                            var mapped = mapToItem(gridView.currentItem, mouse.x, mouse.y);
                            gridView.currentItem.openActionMenu(mapped.x, mapped.y);
                        }
                    } else {
                        var mapped = mapToItem(rootItem, mouse.x, mouse.y);
                        if (typeof contextMenu !== 'undefined') {
                            contextMenu.open(mapped.x, mapped.y);
                        }
                    }
                } else {
                    pressedItem = gridView.currentItem;
                }
            }

            onReleased: mouse => {
                mouse.accepted = true;
                var clickedIndex = updatePositionProperties(mouse.x, mouse.y);

                if (typeof dragHelper === 'undefined' || !dragHelper.dragging) {
                    if (pressedItem && gridView.currentIndex !== -1) {
                        categoryItemGrid.trigger(gridView.currentIndex);
                    } else if (mouse.button === Qt.LeftButton) {
                        categoryItemGrid.trigger(-1);
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
                    if (categoryItemGrid.dragEnabled && pressX !== -1
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
