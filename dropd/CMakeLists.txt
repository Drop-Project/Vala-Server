# Include precompile package
include (ValaPrecompile)

# Configure precompile
vala_precompile (VALA_C
    config.vala
    Application.vala
    Backend/SettingsManager.vala
    Backend/ServiceProvider.vala
    Backend/Server.vala
    Backend/IncomingTransmission.vala
    Backend/Utils.vala
PACKAGES
    granite
    gtk+-3.0
    gio-2.0
    gee-0.8
    avahi-gobject
    posix
OPTIONS
    --thread
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
)

# Add executable
add_executable (dropd ${VALA_C})

# Installation
install (TARGETS dropd RUNTIME DESTINATION bin)