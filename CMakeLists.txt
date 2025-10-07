cmake_minimum_required(VERSION 3.16)

project(MenuWorkspacePlasmoid LANGUAGES CXX)

# Atur C++ standard jika kamu memakai C++
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Cari paket KDE / Qt yang diperlukan
find_package(Qt6 REQUIRED COMPONENTS Core Qml)
find_package(KF6 REQUIRED COMPONENTS Package)

# Jika kamu menggunakan komponen Plasma / KDE untuk plasmoids:
find_package(Plasma REQUIRED)

# Jika ada plugin C++ untuk QML, kita akan buat target library
if (EXISTS "${CMAKE_CURRENT_SOURCE_DIR}/src")
    add_subdirectory(src)
endif()

# Instal direktori plasmoid ke lokasi plasma plasmoids
# DATA_INSTALL_DIR dan SERVICES_INSTALL_DIR berasal dari KDE Frameworks / CMake
include(KF5PackageMacros)
include(FeatureSummary)

# Direktori data (plasmoids) akan diinstal ke ${KDE_INSTALL_DATADIR}/plasma/plasmoids
# Kita menganggap isi plasmoid berada di direktori package/
set(PLASMOID_SOURCE_DIR ${CMAKE_CURRENT_SOURCE_DIR})

install(
  DIRECTORY "${PLASMOID_SOURCE_DIR}"
  DESTINATION ${KDE_INSTALL_DATADIR}/plasma/plasmoids/Menu-Workspace
  PATTERN "CMakeLists.txt" EXCLUDE
)

# metadata.json / desktop file bisa dipasang ke SERVICES_INSTALL_DIR
install(
  FILES "${CMAKE_CURRENT_SOURCE_DIR}/metadata.json"
  DESTINATION ${KDE_INSTALL_KSERVICES5}
)

# Jika ada plugin library dari src, perlu juga melakukan install target-nya
if (TARGET plugin)
    install(
      TARGETS plugin
      DESTINATION ${KDE_INSTALL_PLUGINDIR}/plasma
    )
endif()

feature_summary(WHAT ALL INCLUDE_QUIET_PACKAGES FATAL_ON_MISSING_REQUIRED_PACKAGES)
