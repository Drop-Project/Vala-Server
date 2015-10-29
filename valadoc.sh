#!/bin/sh

rm -rf doc
valadoc \
--metadatadir=/usr/share/gir-1.0 \
--girdir=/usr/share/gir-1.0 \
--importdir=/usr/share/gir-1.0 \
--vapidir=/usr/share/vala-0.30/vapi \
--vapidir=/usr/share/vala/vapi \
--directory=doc \
--pkg=gio-2.0 \
--pkg=drop-1.0 --import=Drop-1.0 \
--package-name=Drop \
--deps