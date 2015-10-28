# Include translations package
include (Translations)

# Configure translations
add_translations_directory ("drop")
add_translations_catalog ("drop"
    ../dropd
    ../dropd/Backend
    ../lib
)