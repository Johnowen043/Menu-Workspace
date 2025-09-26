/*   Copyright (C) 2024-2024 by Randy Abiel Cabrera                        *
 *                                                                         *
 *   This program is free software; you can redistribute it and/or modify  *
 *   it under the terms of the GNU General Public License as published by  *
 *   the Free Software Foundation; either version 2 of the License, or     *
 *   (at your option) any later version.                                   *
 *                                                                         *
 *   This program is distributed in the hope that it will be useful,       *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of        *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the         *
 *   GNU General Public License for more details.                          */

import org.kde.plasma.components 3.0 as PC3
import org.kde.plasma.private.kicker 0.1 as Kicker
import org.kde.coreaddons 1.0 as KCoreAddons
//import org.kde.kquickcontrolsaddons 2.0
import org.kde.plasma.private.quicklaunch 1.0
//import QtQuick.Controls 2.15
import org.kde.ksvg 1.0 as KSvg
//import org.kde.plasma.plasma5support 2.0 as P5Support
//import Qt5Compat.GraphicalEffects
import QtQuick 2.4
import QtQuick.Layouts 1.1
import QtQml 2.15
import org.kde.kirigami 2.0  as Kirigami
import org.kde.plasma.plasmoid 2.0
//import org.kde.kcmutils as KCM
//import org.kde.plasma.private.sessions as Sessions
   Item
   {
    id: rootItem
    property bool showGridFirst: Plasmoid.configuration.showGridFirst // Propiedad de configuración
    property bool searchvisible : Plasmoid.configuration.showSearch
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
    KCoreAddons.KUser {   id: kuser  }
    Logic { id: logic }

    //ghrapics
    KSvg.FrameSvgItem{
        id : headingSvg
        width: parent.width + backgroundSvg.margins.left + backgroundSvg.margins.right
        height: Plasmoid.configuration.showInfoUser ? encabezado.height + Kirigami.Units.smallSpacing : Kirigami.Units.smallSpacing
        y: - backgroundSvg.margins.top
        x: - backgroundSvg.margins.left
        imagePath: "widgets/plasmoidheading"
        prefix: "header"
        opacity: Plasmoid.configuration.transparencyHead * 0.01
        visible: Plasmoid.configuration.showInfoUser}
    KSvg.FrameSvgItem{
        id: footerSvg
        visible: kicker.view_any_controls
        width: parent.width + backgroundSvg.margins.left + backgroundSvg.margins.right
        height:footer.Layout.preferredHeight + 2 + Kirigami.Units.smallSpacing * 3
        y: parent.height + Kirigami.Units.smallSpacing // - (footer.height + Kirigami.Units.smallSpacing)
        x: backgroundSvg.margins.left
        imagePath: "widgets/plasmoidheading"
        prefix: "header"
        transform: Rotation { angle: 180; origin.x: width / 2;}
        opacity: Plasmoid.configuration.transparencyFooter * 0.01}

        Text{
            id: count
            text: i18n("app:" + kicker.count + " row:"+kicker.currentRow +" column:"+kicker.currentColumn +" index:"+kicker.currentIndex + " No filas:" + dynamicRows  + " No columnas:" + dynamicColumns   )
        }
    //contenedor del menu
    ColumnLayout
    {
        id:container
        Layout.preferredHeight: rootItem.space_height
        //encabezado
        Item{id: encabezado
            width: rootItem.space_width
            Layout.preferredHeight: 130
            visible:  Plasmoid.configuration.showInfoUser
            Loader{id: head_
                sourceComponent: headComponent}

        }
        // contendor de busqueda y cuadrilla para cambio dinamico #no funciona
        ColumnLayout
        {
            implicitHeight: (rootItem.searchvisible ? 45 : 0) + (resizeHeight() == 0 ? rootItem.cuadricula_hg  : resizeHeight() -rootItem.visible_items)
            width: rootItem.space_width
            //cuadricula o buscador
            RowLayout
            {  id: cuadricula
                width: rootItem.space_width
                Layout.alignment: rootItem.showGridFirst == true ? Qt.AlignTop : Qt.AlignBottom
                Layout.preferredHeight: resizeHeight() == 0 ? rootItem.cuadricula_hg  : resizeHeight() -rootItem.visible_items
                visible: true
                Loader{id: gridLoader
                sourceComponent: gridComponent}}
            //buscador
            RowLayout
            {   id: rowSearchField
                visible: rootItem.searchvisible
                Layout.alignment: rootItem.showGridFirst == true ? Qt.AlignBottom : Qt.AlignTop
                Layout.preferredHeight:45
                width: rootItem.space_width
                Loader{id: searchLoader
                sourceComponent: searchComponent}
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
            {id: foot_
             sourceComponent: footerComponent}
        }
    }
    //component
    Component {id: footerComponent; Footer{}}
    Component {id: searchComponent; Search{}}
    Component {id: gridComponent;    Grids{}}
    Component {id: headComponent;     Head{}}
    //keys press
    Keys.onPressed: (event) =>
    {
        event.accepted = true; // Asume que todos los eventos se aceptan a menos que se especifique lo contrario
        if (event.modifiers & (Qt.ControlModifier | Qt.ShiftModifier)) { searchLoader.item.gofocus(); return;}
        switch (event.key)
        {
            case Qt.Key_Escape: handleEscape(); break;
            case Qt.Key_Backspace: searchLoader.item.backspace(); break;
            case Qt.Key_Tab:handleTab(); break;
            case Qt.Key_Backtab:handleTab(); break;
            case Qt.Key_Down: handleArrowKeys(1); break;
            case Qt.Key_Up: handleArrowKeys(-1); break;
            case Qt.Key_Left: moveColumn(-1); break;
            case Qt.Key_Right: moveColumn(1); break;
            default: handleTextInput(event.text);break;
        }
    }
    //funciones
    function handleEscape() {
        if (kicker.searching) {reset();}
        else {turnclose();}
    }
    function handleTab() {
        if (kicker.searching) {gridLoader.item.run();}
        else { gridLoader.item.cargar();}
    }
    function moveColumn(direction) {
        if (kicker.currentIndex + direction < 0){kicker.currentIndex=0; kicker.currentRow=0; kicker.currentColumn=0;}
        else if (kicker.currentIndex + direction == (kicker.count) )
        {
            return;
        }
        else
        {
        if (direction > 0)
        { // Mover a la derecha
            kicker.currentColumn += 1;
            if (kicker.currentColumn >= dynamicColumns) {
                kicker.currentColumn = 0; // Regresar a la primera columna
                kicker.currentRow += 1; // Avanzar a la siguiente fila
            }
        }
        else if (direction < 0)
        { // Mover a la izquierda
            kicker.currentColumn -= 1;
            if (kicker.currentColumn < 0)
            {kicker.currentColumn = dynamicColumns - 1; // Regresar a la última columna
             kicker.currentRow -= 1; // Retroceder a la fila anterior
            }
        }
        // Asegúrate de no pasar del límite de filas
        if (kicker.currentRow < 0){kicker.currentRow = 0;} // Mantener en la primera fila
        else if (kicker.currentRow >= dynamicRows) {kicker.currentRow = dynamicRows - 1;} // Ajustar a la última fila válida
        gridLoader.item.gridtryActivate(kicker.currentRow, kicker.currentColumn);
        }
    }
    function handleArrowKeys(direction) {
        if (direction === 1) { // Flecha abajo
            kicker.currentRow += 1;
        } else if (direction === -1) { // Flecha arriba
            kicker.currentRow -= 1;
        }

        // Controlar límites de filas
        if (kicker.currentRow < 0) {
            kicker.currentRow = 0; // Mantener en la primera fila
        } else if (kicker.currentRow >= dynamicRows) {
            kicker.currentRow = dynamicRows - 1; // Ajustar a la última fila válida
        }
        gridLoader.item.gridtryActivate(kicker.currentRow, kicker.currentColumn);

    }
    function handleTextInput(text) {
        if (text !== "") {
            searchLoader.item.appendText(text);
            searchLoader.item.gofocus();
            kicker.currentIndex = 0;
            kicker.currentColumn = 0;
            kicker.currentRow = 0;
        }
    }
    function updateDimensions()
    {
        // Recalcula el número dinámico de columnas y filas
        dynamicColumns = Math.floor((resizeWidth()  == 0 ? rootItem.calc_width : resizeWidth()) / kicker.cellSizeWidth);
        dynamicRows = Math.ceil(kicker.count / dynamicColumns);
    }
    //otras funciones
    function turnclose()
    {
        searchLoader.item.emptysearch()
        kicker.searching=false;
        showFavorites=false;
        kicker.currentIndex=0;
        kicker.currentColumn=0;
        kicker.currentRow=0;
        gridLoader.item.cargar()
        kicker.expanded = false;
        return
    }
    function reset()
    {
        kicker.currentIndex=0
        kicker.currentColumn=0
        kicker.currentRow=0
        searchLoader.item.emptysearch()
        kicker.searching=false;
        gridLoader.item.reset()
        //gridLoader.item.mainColumn.tryActivate(0,0)
    }
    function resizeWidth()
    {   var screenAvail = kicker.availableScreenRect;
        var screenGeom = kicker.screenGeometry;
        var screen = Qt.rect(screenAvail.x + screenGeom.x,screenAvail.y + screenGeom.y,screenAvail.width, screenAvail.height);
        if (screen.width > (kicker.cellSizeWidth *  Plasmoid.configuration.numberColumns) + Kirigami.Units.gridUnit){ return 0; }
        else { return screen.width - Kirigami.Units.gridUnit * 2 ; }
    }
    function resizeHeight()
    {   var screenAvail = kicker.availableScreenRect;
        var screenGeom = kicker.screenGeometry;
        var screen = Qt.rect(screenAvail.x + screenGeom.x,screenAvail.y + screenGeom.y,screenAvail.width, screenAvail.height);
        if (screen.height > (kicker.cellSizeHeight *  Plasmoid.configuration.numberRows) + rootItem.visible_items + Kirigami.Units.gridUnit * 1.5) {return 0;}
        else { return screen.height - Kirigami.Units.gridUnit * 2;}
    }
    function updateLayouts()
    {   rootItem.searchvisible = Plasmoid.configuration.showSearch;
        rootItem.visible_items = (Plasmoid.configuration.showInfoUser ? headingSvg.height : 0) + (rootItem.searchvisible == true ? rowSearchField.height : 0) + ( kicker.view_any_controls == true ? footer.height : 0)+ Kirigami.Units.gridUnit
        rootItem.cuadricula_hg = (kicker.cellSizeHeight *  Plasmoid.configuration.numberRows);
        rootItem.calc_width = (kicker.cellSizeWidth *  Plasmoid.configuration.numberColumns) + Kirigami.Units.gridUnit;
        rootItem.calc_height = rootItem.cuadricula_hg  + rootItem.visible_items;
        rootItem.userShape = calculateUserShape(Plasmoid.configuration.userShape);
    }
    function calculateUserShape(shape)
    {   switch (shape) {
        case 0: return (kicker.sizeImage * 0.85) / 2;
        case 1: return 8;
        case 2: return 0;
        default:return (kicker.sizeImage * 0.85) / 2;}
    }
    //changed
    onWidthChanged: {updateDimensions(); updateLayouts(); }
    onHeightChanged:{ updateDimensions(); updateLayouts();}

    Component.onCompleted:
    {
    rootModel.refreshed.connect(gridLoader.item.setModels)
    rootModel.refresh();
    reset();
    }
}
