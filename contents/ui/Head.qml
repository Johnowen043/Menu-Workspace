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


RowLayout
{
    id: headComponent
    SequentialAnimation
    {
        running: true
        loops: Animation.Infinite

        // Opacity animation
        PropertyAnimation
        {
            target: alo_user
            property: "opacity"
            from: 0.2
            to: 0.8
            duration: 2000
            easing.type: Easing.InOutQuad
        }
        // Second phase of opacity animation
        PropertyAnimation
        {
            target: alo_user
            property: "opacity"
            from:0.8
            to: 0.2
            duration: 2000
            easing.type: Easing.InOutQuad
        }
    }

    width: (rootItem.resizeWidth()  == 0 ? rootItem.calc_width : rootItem.resizeWidth())
    Rectangle
    {
        width:  60
        color: 'transparent'
    }

    Item {Layout.fillWidth: true}

    ColumnLayout
    {
        Layout.alignment: Qt.AlignHCenter |  Qt.AlignVCenter
        visible: iconUser.source !== "" && Plasmoid.configuration.showInfoUser
        Rectangle
        {
            Layout.alignment: Qt.AlignHCenter |  Qt.AlignVCenter
            width: kicker.sizeImage*0.83
            height: width
            color: 'transparent'
            Rectangle
            {
                id: alo_user
                anchors.centerIn: parent
                width: kicker.sizeImage*0.83
                height: width
                color: 'transparent'
                radius: userShape
                clip: true
                visible: iconUser.source !== "" && Plasmoid.configuration.showInfoUser
                z: 1

                // Enhanced rainbow ring with solid colors
                Rectangle {
                    id: rainbowRing
                    anchors.fill: parent
                    radius: parent.radius
                    opacity: 1.0

                    // Using radial gradient for better compatibility
                    gradient: Gradient {
                        GradientStop { position: 0.0; color: "#FF1744" }   // Solid Red
                        GradientStop { position: 0.166; color: "#FF9800" } // Solid Orange
                        GradientStop { position: 0.333; color: "#FFEB3B" } // Solid Yellow
                        GradientStop { position: 0.5; color: "#4CAF50" }   // Solid Green
                        GradientStop { position: 0.666; color: "#2196F3" } // Solid Blue
                        GradientStop { position: 0.833; color: "#9C27B0" } // Solid Purple
                        GradientStop { position: 1.0; color: "#FF1744" }   // Back to Red
                    }

                    // Smooth rotation animation
                    RotationAnimator on rotation {
                        loops: Animation.Infinite
                        duration: 4000
                        from: 0
                        to: 360
                        running: true
                        easing.type: Easing.Linear
                    }

                    // Add subtle scale animation
                    SequentialAnimation on scale {
                        loops: Animation.Infinite
                        PropertyAnimation {
                            from: 1.0
                            to: 1.02
                            duration: 3000
                            easing.type: Easing.InOutQuad
                        }
                        PropertyAnimation {
                            from: 1.02
                            to: 1.0
                            duration: 3000
                            easing.type: Easing.InOutQuad
                        }
                    }
                }

                Rectangle {
                    id: mask2
                    width: parent.width * 0.9
                    height: parent.height * 0.9
                    anchors.centerIn: parent
                    visible: false
                    radius: userShape
                }

                Image {
                    width: parent.width * 0.9
                    height: parent.height * 0.9
                    anchors.centerIn: parent
                    id: iconUser2
                    source: kuser.faceIconUrl
                    cache: false
                    visible: source !== "" && Plasmoid.configuration.showInfoUser
                    sourceSize.width: kicker.sizeImage
                    sourceSize.height: kicker.sizeImage
                    fillMode: Image.PreserveAspectFit
                    layer.enabled: true
                    layer.effect: OpacityMask {
                        maskSource: mask2
                    }
                }
            }

            Rectangle
            {
                anchors.centerIn: parent
                width: kicker.sizeImage*.7
                height: width
                color: 'transparent'
                z: 2
                radius: userShape
                clip: true
                visible: iconUser.source !== "" && Plasmoid.configuration.showInfoUser
                Rectangle
                {
                    id: mask
                    width: parent.width
                    height: parent.height
                    visible: false
                    radius: userShape
                }
                Image
                {
                    id: iconUser
                    width: parent.width
                    height: parent.height
                    source: kuser.faceIconUrl
                    cache: false
                    visible: source !== "" && Plasmoid.configuration.showInfoUser
                    sourceSize.width: kicker.sizeImage
                    sourceSize.height: kicker.sizeImage
                    fillMode: Image.PreserveAspectFit
                    layer.enabled:true
                    layer.effect: OpacityMask {maskSource: mask}
                    transitions: Transition { PropertyAnimation { properties: "opacity,y"; easing.type: Easing.InOutQuad; }}
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        acceptedButtons: Qt.LeftButton
                        onClicked: KCM.KCMLauncher.openSystemSettings("kcm_users")}
                }
            }
        }
        Kirigami.Heading
        {
            id: textouser
            visible: iconUser.source !== "" && Plasmoid.configuration.showInfoUser
            Layout.alignment: Qt.AlignVCenter
            color: Kirigami.Theme.textColor
            level: 4
            text: i18n("Hello, ")+ kuser.fullName
            font.weight: Font.Bold
        }
        TextMetrics
        {
            id: headingMetrics
            //font: dummyHeading.font
        }
    }
    Item {Layout.fillWidth: true}
    PC3.ToolButton
    {
        id: configureButton
        Layout.alignment: Qt.AlignRight | Qt.AlignTop
        visible: Plasmoid.internalAction("configure").enabled | iconUser.source !== "" && Plasmoid.configuration.showInfoUser
        icon.name: "configure"
        text: Plasmoid.internalAction("configure").text
        display: PC3.ToolButton.IconOnly
        PC3.ToolTip.text: text
        PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
        PC3.ToolTip.visible: hovered
        onClicked: plasmoid.internalAction("configure").trigger()
    }
    PC3.ToolButton
    {
        id: pinButton
        Layout.alignment: Qt.AlignRight | Qt.AlignTop
        visible: iconUser.source !== "" && Plasmoid.configuration.showInfoUser
        checkable: true
        checked: Plasmoid.configuration.pin
        icon.name: "window-pin"
        text: i18n("Keep Open")
        display: PC3.ToolButton.IconOnly
        PC3.ToolTip.text: text
        PC3.ToolTip.delay: Kirigami.Units.toolTipDelay
        PC3.ToolTip.visible: hovered
        Binding {
            target: kicker
            property: "hideOnWindowDeactivate"
            value: !Plasmoid.configuration.pin
            // there should be no other bindings, so don't waste resources
        }
        onToggled: Plasmoid.configuration.pin = checked
    }
}
