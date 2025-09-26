
import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Layouts 1.15
import QtQuick.Controls as QQC2

import org.kde.kirigami 2.19 as Kirigami
import org.kde.plasma.core as PlasmaCore
import org.kde.plasma.plasmoid 2.0
import org.kde.kcmutils as KCM

import org.kde.plasma.workspace.dbus as DBus

KCM.SimpleKCM
{


    property alias cfg_rebootEnabled: rebootEnabled.checked
    property alias cfg_shutDownEnabled: shutDownEnabled.checked
    property alias cfg_logOutEnabled: logOutEnabled.checked
    property alias cfg_sleepEnabled: sleepEnabled.checked
    property alias cfg_lockScreenEnabled: lockScreenEnabled.checked


    property alias cfg_aboutThisComputerEnabled: aboutThisComputerEnabled.checked
    property alias cfg_aboutThisComputerSettings: aboutThisComputerSettings.text

    property alias cfg_systemPreferencesEnabled: systemPreferencesEnabled.checked
    property alias cfg_systemPreferencesSettings: systemPreferencesSettings.text

    property alias cfg_appStoreEnabled: appStoreEnabled.checked
    property alias cfg_appStoreSettings: appStoreSettings.text

    property alias cfg_forceQuitEnabled: forceQuitEnabled.checked
    property alias cfg_forceQuitSettings: forceQuitSettings.text

    property alias cfg_homeEnabled: homeEnabled.checked
    property alias cfg_homeSettings: homeSettings.text

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right
    }
    ColumnLayout
    {

        // Checkbox for Reset/Reiniciar
        RowLayout {
            CheckBox {
                id: rebootEnabled
                text: i18n("Reset / Reiniciar")
                checked: showAdvancedMode.checked
                onCheckedChanged: {
                    rebootSettings.enabled = checked
                }
            }
        }
        // Checkbox for Shut down/Apagar
        RowLayout {
            CheckBox {
                id: shutDownEnabled
                text: i18n("Shut down / Apagar")
                checked: showAdvancedMode.checked
                onCheckedChanged: {
                    shutDownSettings.enabled = checked
                }
            }
        }
        // Checkbox for Log Out
        RowLayout {
            CheckBox {
                id: logOutEnabled
                text: i18n("Log Out / Cerrar sesión")
                checked: showAdvancedMode.checked
                onCheckedChanged: {
                    logOutSettings.enabled = checked
                }
            }
        }
        // Checkbox for About This Computer
        RowLayout {
            CheckBox {
                id: aboutThisComputerEnabled
                text: i18n("About This Computer / Acerca de este equipo")
                checked: showAdvancedMode.checked
                onCheckedChanged: {
                    aboutThisComputerSettings.enabled = checked
                }
            }
            Kirigami.ActionTextField {
                id: aboutThisComputerSettings
                enabled: aboutThisComputerEnabled.checked
                rightActions: QQC2.Action {
                    icon.name: "edit-clear"
                    enabled: aboutThisComputerSettings.text !== ""
                    text: i18nc("@action:button", "Reset command")
                    onTriggered: {
                        aboutThisComputerSettings.clear()
                        root.cfg_aboutThisComputerSettings = ""
                    }
                }
            }
        }
        // Checkbox for System Preferences
        RowLayout {
            CheckBox {
                id: systemPreferencesEnabled
                text: i18n("System Preferences / Preferencias del sistema")
                checked: showAdvancedMode.checked
                onCheckedChanged: {
                    systemPreferencesSettings.enabled = checked
                }
            }

            Kirigami.ActionTextField {
                id: systemPreferencesSettings
                enabled: systemPreferencesEnabled.checked
                rightActions: QQC2.Action {
                    icon.name: "edit-clear"
                    enabled: systemPreferencesSettings.text !== ""
                    text: i18nc("@action:button", "Reset command")
                    onTriggered: {
                        systemPreferencesSettings.clear()
                        root.cfg_systemPreferencesSettings = ""
                    }
                }
            }
        }
        // Checkbox for System Preferences
        RowLayout {
            CheckBox {
                id: homeEnabled
                text: i18n("home / Directorio de usuario")
                checked: showAdvancedMode.checked
                onCheckedChanged: {
                    homeSettings.enabled = checked
                }
            }

            Kirigami.ActionTextField {
                id: homeSettings
                enabled: homeEnabled.checked
                rightActions: QQC2.Action {
                    icon.name: "edit-clear"
                    enabled: homeSettings.text !== ""
                    text: i18nc("@action:button", "Reset command")
                    onTriggered: {
                        homeSettings.clear()
                        root.cfg_systemPreferencesSettings = ""
                    }
                }
            }
        }
        // Checkbox for App Store
        RowLayout {
            CheckBox {
                id: appStoreEnabled
                text: i18n("App Store / App Store")
                checked: showAdvancedMode.checked
                onCheckedChanged: {
                    appStoreSettings.enabled = checked
                }
            }
            Kirigami.ActionTextField {
                id: appStoreSettings
                enabled: appStoreEnabled.checked
                rightActions: QQC2.Action {
                    icon.name: "edit-clear"
                    enabled: appStoreSettings.text !== ""
                    text: i18nc("@action:button", "Reset command")
                    onTriggered: {
                        appStoreSettings.clear()
                        root.cfg_appStoreSettings = ""
                    }
                }
            }
        }
        // Checkbox for Force Quit
        RowLayout {
            CheckBox {
                id: forceQuitEnabled
                text: i18n("Force Quit / Forzar salida")
                checked: showAdvancedMode.checked
                onCheckedChanged: {
                    forceQuitSettings.enabled = checked
                }
            }
            Kirigami.ActionTextField {
                id: forceQuitSettings
                enabled: forceQuitEnabled.checked
                rightActions: QQC2.Action {
                    icon.name: "edit-clear"
                    enabled: forceQuitSettings.text !== ""
                    text: i18nc("@action:button", "Reset command")
                    onTriggered: {
                        forceQuitSettings.clear()
                            root.cfg_forceQuitSettings = ""
                    }
                }
            }
        }
        // Checkbox for Sleep
        RowLayout {
            CheckBox {
                id: sleepEnabled
                text: i18n("Sleep / Suspender")
                checked: showAdvancedMode.checked
                onCheckedChanged: {
                    sleepSettings.enabled = checked
                }
            }
        }
        // Checkbox for Lock Screen
        RowLayout {
            CheckBox {
                id: lockScreenEnabled
                text: i18n("Lock Screen / Bloquear pantalla")
                checked: showAdvancedMode.checked
                onCheckedChanged: {
                    lockScreenSettings.enabled = checked
                }
            }
        }
    }
}
