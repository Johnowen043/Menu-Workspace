import QtQuick 2.15
import QtQuick.Layouts 1.15
import org.kde.plasma.components as PlasmaComponents
import org.kde.kirigami 2.20 as Kirigami
import org.kde.plasma.private.kicker 0.1 as Kicker

// FIXED: Uses ItemMultiGrid pattern to properly display categorized search results
PlasmaComponents.ScrollView {
    id: searchResultsGrid

    property alias model: repeater.model
    property int cellWidth: 118
    property int cellHeight: 118
    property int iconSize: Kirigami.Units.iconSizes.huge
    property bool showLabels: true
    property bool searching: false
    property string searchQuery: ""

    property int currentIndex: -1
    property int count: getTotalCount()

    signal keyNavUp()
    signal keyNavDown()
    signal keyNavLeft()
    signal keyNavRight()
    signal itemActivated(int index, string actionId, string argument)

    anchors.fill: parent
    implicitHeight: itemColumn.implicitHeight

    // Calculate total items across all categories
    function getTotalCount() {
        var total = 0;
        if (!model || !model.modelForRow) return 0;

        for (var i = 0; i < model.count; i++) {
            var categoryModel = model.modelForRow(i);
            if (categoryModel && categoryModel.count > 0) {
                total += categoryModel.count;
            }
        }
        return total;
    }

    function subGridAt(index) {
        if (index >= 0 && index < repeater.count) {
            return repeater.itemAt(index).itemGrid;
        }
        return null;
    }

    function selectFirst() {
        for (var i = 0; i < repeater.count; i++) {
            var grid = subGridAt(i);
            if (grid && grid.count > 0) {
                grid.currentIndex = 0;
                grid.focus = true;
                currentIndex = 0;
                console.log("SEARCH: Selected first item in category", i);
                return;
            }
        }
    }

    function tryActivate(row, col) {
        selectFirst();
    }

    function triggerSelected() {
        // Find the focused grid and trigger it
        for (var i = 0; i < repeater.count; i++) {
            var grid = subGridAt(i);
            if (grid && grid.focus && grid.currentIndex !== -1) {
                console.log("SEARCH TRIGGER: Category", i, "Index", grid.currentIndex);
                if (grid.model && grid.model.trigger) {
                    grid.model.trigger(grid.currentIndex, "", null);
                    itemActivated(grid.currentIndex, "", "");
                    kicker.expanded = false;
                    return true;
                }
            }
        }
        return false;
    }

    function trigger(index) {
        triggerSelected();
    }

    Flickable {
        id: flickable
        flickableDirection: Flickable.VerticalFlick
        contentHeight: itemColumn.implicitHeight

        Column {
            id: itemColumn
            width: searchResultsGrid.width - Kirigami.Units.gridUnit
            spacing: Kirigami.Units.largeSpacing

            Repeater {
                id: repeater

                delegate: Item {
                    width: itemColumn.width
                    height: categoryHeader.height + gridView.height + Kirigami.Units.largeSpacing * 2
                    visible: gridView.count > 0

                    property Item itemGrid: gridView

                    // Category header
                    Kirigami.Heading {
                        id: categoryHeader
                        anchors.top: parent.top
                        x: Kirigami.Units.smallSpacing
                        width: parent.width - x
                        height: dummyHeading.height

                        level: 4
                        font.bold: true
                        font.weight: Font.DemiBold
                        color: Kirigami.Theme.textColor
                        opacity: 0.8

                        text: {
                            if (repeater.model && repeater.model.modelForRow) {
                                var categoryModel = repeater.model.modelForRow(index);
                                return categoryModel ? categoryModel.description || "Results" : "Results";
                            }
                            return "Results";
                        }
                        textFormat: Text.PlainText
                        elide: Text.ElideRight
                        wrapMode: Text.NoWrap
                    }

                    // Separator line
                    Rectangle {
                        anchors.right: parent.right
                        anchors.left: categoryHeader.right
                        anchors.leftMargin: Kirigami.Units.largeSpacing
                        anchors.rightMargin: Kirigami.Units.largeSpacing
                        anchors.verticalCenter: categoryHeader.verticalCenter
                        height: 1
                        color: Kirigami.Theme.textColor
                        opacity: 0.15
                    }

                    // Results grid for this category
                    ItemGridView {
                        id: gridView

                        anchors {
                            top: categoryHeader.bottom
                            topMargin: Kirigami.Units.largeSpacing
                        }

                        width: parent.width
                        height: Math.ceil(count / Math.floor(width / cellWidth)) * searchResultsGrid.cellHeight
                        cellWidth: searchResultsGrid.cellWidth
                        cellHeight: searchResultsGrid.cellHeight
                        iconSize: searchResultsGrid.iconSize
                        showLabels: searchResultsGrid.showLabels

                        verticalScrollBarPolicy: PlasmaComponents.ScrollBar.AlwaysOff
                        dragEnabled: false
                        dropEnabled: false

                        model: repeater.model ? repeater.model.modelForRow(index) : null

                        onCountChanged: {
                            console.log("SEARCH CATEGORY", index, "count:", count);

                            // Auto-focus first category with results
                            if (searchResultsGrid.searching && index === 0 && count > 0 && currentIndex === -1) {
                                Qt.callLater(function() {
                                    if (count > 0) {
                                        currentIndex = 0;
                                        focus = true;
                                        console.log("SEARCH: Auto-focused first result");
                                    }
                                });
                            }
                        }

                        onFocusChanged: {
                            if (focus) {
                                searchResultsGrid.focus = true;
                            }
                        }

                        onCurrentItemChanged: {
                            if (!currentItem) return;

                            // Scroll to keep current item visible
                            var y = currentItem.y;
                            y = contentItem.mapToItem(flickable.contentItem, 0, y).y;

                            if (y < flickable.contentY) {
                                flickable.contentY = y;
                            } else {
                                y += searchResultsGrid.cellHeight;
                                y -= flickable.contentY;
                                y -= searchResultsGrid.height;

                                if (y > 0) {
                                    flickable.contentY += y;
                                }
                            }
                        }

                        Keys.onPressed: function(event) {
                            if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                                event.accepted = true;
                                if (model && model.trigger && currentIndex !== -1) {
                                    console.log("SEARCH ENTER: Triggering index", currentIndex);
                                    model.trigger(currentIndex, "", null);
                                    kicker.expanded = false;
                                }
                            }
                        }

                        onKeyNavUp: {
                            if (index > 0) {
                                // Move to previous category
                                for (var i = index - 1; i >= 0; i--) {
                                    var prevGrid = searchResultsGrid.subGridAt(i);
                                    if (prevGrid && prevGrid.count > 0) {
                                        prevGrid.tryActivate(prevGrid.lastRow(), currentCol());
                                        break;
                                    }
                                }
                                if (i < 0) {
                                    searchResultsGrid.keyNavUp();
                                }
                            } else {
                                searchResultsGrid.keyNavUp();
                            }
                        }

                        onKeyNavDown: {
                            if (index < repeater.count - 1) {
                                // Move to next category
                                for (var i = index + 1; i < repeater.count; i++) {
                                    var nextGrid = searchResultsGrid.subGridAt(i);
                                    if (nextGrid && nextGrid.count > 0) {
                                        nextGrid.tryActivate(0, currentCol());
                                        break;
                                    }
                                }
                                if (i >= repeater.count) {
                                    searchResultsGrid.keyNavDown();
                                }
                            } else {
                                searchResultsGrid.keyNavDown();
                            }
                        }
                    }

                    // Intercept wheel events for smooth scrolling
                    Kicker.WheelInterceptor {
                        anchors.fill: gridView
                        z: 1
                        destination: findWheelArea(searchResultsGrid)
                    }
                }
            }
        }
    }

    // Monitor model changes
    Connections {
        target: model
        function onCountChanged() {
            console.log("SEARCH MODEL: Category count =", model ? model.count : 0);
            searchResultsGrid.count = getTotalCount();

            if (searching && getTotalCount() > 0) {
                Qt.callLater(function() {
                    selectFirst();
                });
            }
        }
    }

    onVisibleChanged: {
        console.log("SEARCH GRID: Visibility =", visible, "| Total items =", getTotalCount());
        if (visible && getTotalCount() > 0) {
            Qt.callLater(function() {
                selectFirst();
            });
        }
    }

    Component.onCompleted: {
        console.log("SEARCH GRID: Initialized (ItemMultiGrid style)");
    }
}
