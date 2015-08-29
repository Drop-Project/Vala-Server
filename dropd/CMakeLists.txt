# Include precompile package
include (ValaPrecompile)

# Configure precompile
vala_precompile (VALA_C
    config.vala
    Application.vala
PACKAGES
    granite
    gtk+-3.0
    gio-2.0
    gee-0.8
OPTIONS
    --thread
)

# Add executable
add_executable (dropd ${VALA_C})

# Installation
install (TARGETS dropd RUNTIME DESTINATION bin)