# Configure precompile
vala_precompile (VALA_C
    config.vala
    Application.vala
    Backend/SettingsManager.vala
    Backend/DBusInterface.vala
    Backend/ServiceProvider.vala
    Backend/ServiceBrowser.vala
    Backend/Server.vala
    Backend/ServerPort.vala
    Backend/ProtocolImplementation.vala
    Backend/IncomingTransmission.vala
    Backend/OutgoingTransmission.vala
    Backend/Utils.vala
PACKAGES
    granite
    gio-2.0
    gee-0.8
    avahi-gobject
    avahi-client
    posix
OPTIONS
    --thread
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
    --target-glib 2.32
)

# Add executable
add_executable (dropd ${VALA_C})

# Installation
install (TARGETS dropd RUNTIME DESTINATION bin)