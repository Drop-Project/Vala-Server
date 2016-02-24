# Configure precompile
vala_precompile (DIALOG_VALA_C
    config.vala
    Application.vala
    MainWindow.vala
PACKAGES
    granite
    gio-2.0
    gee-0.8
    drop-1.0
OPTIONS
    --thread
    --vapidir=${CMAKE_SOURCE_DIR}/vapi
    --vapidir=${CMAKE_CURRENT_BINARY_DIR}/../lib
    --target-glib 2.32
)

# Add executable
add_executable (drop-dialog ${DIALOG_VALA_C})

# Installation
install (TARGETS drop-dialog RUNTIME DESTINATION bin)