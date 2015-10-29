# Configure precompile
vala_precompile (LIB_VALA_C
    Session.vala
    Interfaces.vala
    IncomingTransmission.vala
    OutgoingTransmission.vala
    Settings.vala
PACKAGES
    gio-2.0
    granite
OPTIONS
    --thread
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
    --target-glib 2.32
GENERATE_VAPI
    ${LIB_NAME}
GENERATE_HEADER
    ${CMAKE_PROJECT_NAME}
)

# Add executable
add_library (${LIB_NAME} SHARED ${LIB_VALA_C})

# Set library properties
set_target_properties (${LIB_NAME} PROPERTIES
    OUTPUT_NAME ${LIB_NAME}
    VERSION ${LIB_SOVERSION}.${LIB_VERSION}
    SOVERSION ${LIB_SOVERSION}
)

# Installation
install (TARGETS ${LIB_NAME} DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR}/)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${LIB_NAME}.pc DESTINATION ${CMAKE_INSTALL_FULL_LIBDIR}/pkgconfig/)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${LIB_NAME}.vapi DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/vala/vapi/)
install (FILES ${CMAKE_CURRENT_SOURCE_DIR}/${LIB_NAME}.deps DESTINATION ${CMAKE_INSTALL_FULL_DATAROOTDIR}/vala/vapi/)
install (FILES ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.h DESTINATION ${CMAKE_INSTALL_FULL_INCLUDEDIR}/${LIB_NAME}/)

# Include GObject Introspection
#include (FindGObjectIntrospection)

# Try to generate an introspection file
#if (INTROSPECTION_FOUND)
#    include (GObjectIntrospectionMacros)
#    add_target_gir (${LIB_NAME} Drop ${CMAKE_CURRENT_BINARY_DIR}/${CMAKE_PROJECT_NAME}.h "${LIB_CFLAGS}" ${LIB_VERSION} Gio-2.0 Granite-1.0)
#endif ()
