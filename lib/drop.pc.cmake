prefix=@PREFIX@
exec_prefix=@DOLLAR@{prefix}
libdir=@DOLLAR@{prefix}/lib
includedir=@DOLLAR@{prefix}/include/

Name: Drop
Description: Drop headers
Version: 2.0
Libs: -ldrop-1.0
Cflags: -I@DOLLAR@{includedir}/drop-1.0
Requires: glib-2.0 gee-0.8