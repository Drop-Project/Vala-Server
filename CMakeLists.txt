# Project name
project (drop)

# Minimum requirements of build-system
cmake_minimum_required (VERSION 2.8)
cmake_policy (VERSION 2.6)

# Configuration
set (DATADIR "${CMAKE_INSTALL_PREFIX}/share")
set (PKGDATADIR "${DATADIR}/drop")
set (GETTEXT_PACKAGE "drop")
set (RELEASE_NAME "drop")
set (VERSION "0.1")
set (VERSION_INFO "Release")
set (PREFIX ${CMAKE_INSTALL_PREFIX})
set (DOLLAR "$")

# Cmake-files
list (APPEND CMAKE_MODULE_PATH ${CMAKE_SOURCE_DIR}/cmake)

# Configuration file
configure_file (${CMAKE_SOURCE_DIR}/dropd/config.vala.cmake ${CMAKE_SOURCE_DIR}/dropd/config.vala)

# Check for vala
find_package (Vala REQUIRED)
include (ValaVersion)
ensure_vala_version ("0.18" MINIMUM)
include (ValaPrecompile)

# Disable C compiler warnings
add_definitions (-w)

# Set gettext-package
add_definitions (-DGETTEXT_PACKAGE="drop")

# Check for required dependencies
find_package (PkgConfig)
pkg_check_modules (DEPS REQUIRED granite gtk+-3.0 gthread-2.0 gio-2.0 gee-0.8 avahi-gobject avahi-client)

# Link the avahi library
add_definitions (-lavahi)

# Link dependencies
add_definitions (${DEPS_CFLAGS})
link_libraries (${DEPS_LIBRARIES})
link_directories (${DEPS_LIBRARY_DIRS})

# Load directories
add_subdirectory (dropd)
add_subdirectory (po)
add_subdirectory (data)
add_subdirectory (schemas)